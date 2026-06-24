```
tags: paru, apparmor, selinux, containers, devops
```

# AppArmor

**AppArmor** - простой и эффективный способ в Linux настроить разрешения для системы (security), это проактивная система защиты ОС и приложений. Это Linux Security Module (LSM), apparmor работает на уровне системы (в отличие антивирусов, которые являются процессом в системе).

AppArmor блокирует не разрешенные команды, а не ищет вирусы/уязвимости. При сборке AUR (makepkg, etc.) вызываются команды, которые не разрешены в профиле AppArmor для пользователя-сборщика. Например, в *enforce* режиме для всех процессов и отсутствия профиля для makepkg или gcc, сборка упадет с ошибкой доступа.

При запуске установленной из AUR программы: если нет готового профиля AppArmor для этой программы, она будет работать в неограниченном режиме (complain или unconfined), что лишает смысла использование AppArmor для неё.

SELinux не поддерживается в arch/cachyos, есть пакеты `selinux-*`. SELinux использует политики, жестко встроенные в систему, которых в arch/cachyos нету.

Я использую `paru`, он запрещает установку от root и использует `sudo` при необходимости. Для защиты `.ssh`, `.config`, `sudo with NOPASSWD` etc. используется `--chroot` (**Chroot-bundle**), пакет будет собран в `systemd-nspawn` контейнере. Изоляция файловой системы - вредонос будет видеть только минимальный chroot, не home.

### Для Docker/Podman.

Docker по умолчанию использует встроенный профиль AppArmor с именем docker-default. Он ограничивает возможности контейнера: запрещает монтирование, доступ к некоторым syscall-s, привилегированные операции. Профиль довольно либеральный — подходит для большинства контейнеров, но не для привилегированных.

```bash
sudo aa-status | grep docker
sudo cat /sys/kernel/security/apparmor/profiles | grep docker
```

Если в системе AppArmor включен (Pop!_OS и Mint по умолчанию), то docker/podman будет автоматически использовать свой профиль.

В podman можно посмотреть профиль через `podman inspect <target> --format '{{.AppArmorProfile}}'`, по умолчанию `container-default`, схожий с `docker-default`, если контейнер имеет свой профиль AppArmor (`--security-opt apparmor=customprofile`), podman будет использовать его.

```bash
podman run --security-opt apparmor=unconfined ...  # turn off
podman run --security-opt apparmor=untrusted-container-profile ...  # turn on
```

Системы с SELinux (Fedora, RHEL), podman будет использовать SELinux, а AppArmor игнорироваться.

### Audit & Tests

`audit2allow` для selinux или `aa-logprof` для apparmor что бы посмотреть какие действия блокируются профилем.

### Атака через Supply Chain (AUR Malware - June 2026)

> [!TLDR] 1600+ AUR packages compromised by attackers who injected npm install atomic-lockfile, bun install js-digest, or lockfile-js into PKGBUILD/install files. Two attack waves:
>
> atomic-lockfile / lockfile-js (npm) - accounts krisztinavarga, franziskaweber, tobiaswesterburg, ellenmyklebust; arojas (impersonated legitimate maintainer - see Impersonation Clarification)
> js-digest (bun) - accounts custodiatovar, veramagalhaes
> Both deliver an infostealer and eBPF rootkit targeting developer credentials, browser data, and CI/CD secrets.

При запуске makepkg (через paru) эти команды скачивали и выполняли вредоносный код на стороне клиента.
Вредоносный код считывал токены, браузерные данные, секреты и пытался установить eBPF-руткит для сокрытия следов.
Критично: вся атака выполняется в контексте того же пользователя, который запускает makepkg / paru. Никакого повышения привилегий не требуется.

**Че с AppArmor**:
- Можем Запретить выполнение npm, bun, node во время работы makepkg, если они не разрешены в профиле.
- Можем запретить сетевые соединения во время сборки (или ограничить их DNS + строгий аутгоинг).
- Можем запретить загрузку и запись модулей eBPF через bpf() (очень важный признак руткита).
- Можем ограничить запись в файлы конфигурации браузеров, SSH-ключи, .env, CI-переменные и т.д.
- Не можем защитить если злоумышленник действует через уже скомпрометированный профиль (профиль разрешает `npm install`).
- Не защитит при игнорирование предупреждений и unsafe флагов как `--skipchecksums` (не проверяет контрольные суммы) или `--noconfirm`.


**Блокировка eBPF-руткита**, вредонос пытался загрузить eBPF-программу в ядро. Для этого требуется `cap_sys_admin` или `CAP_BPF`. AppArmor может блокировать эти capability.


### Best Practices & Patterns

Для AUR сложно настроить правильные разрешения, можно установить AppArmor в режим *complain* (логировать нарушения, но не блокировать) для отладки. Использовать apparmor профили для популярных пакетов.

### DRAFT

AppArmor позволяет усилить контроль над используемыми инструментами в системе (gcc, pacman, makepkg, strip, ld, etc.). 

SELinux требует более сложного и детального конфига, что делает его сомнительно-пригодным для workstation.

### Setup AppArmor for Arch/CachyOS

1. Включить AppArmor:
```bash
sudo aa-status # если загружен apparmor, то покажет профили
cat /proc/cmdline | grep apparmor # apparmor=1 security=apparmor
sudoedit /etc/default/grub
  # добавить GRUB_CMDLINE_LINUX_DEFAULT="... apparmor=1 security=apparmor"
sudo update-grub # обновить конфиг GRUB
```
> Ядро может не поддерживать apparmor (linux, zen, cachyos должны поддерживать).

Установка инструементов:
```bash
sudo paru -S apparmor audit
sudo systemctl enable --now apparmor
sudo systemctl enable --now auditd   # для логов доменных событий
```

2. Создать минимальные профили (только complain - логировать нарушения, но не блокировать) для ключевых тулзов и как в дальнейшем их расширять:
```bash
# makepkg (скрипт сборки)
sudo aa-complain /usr/bin/makepkg
# pacman (транзакции с пакетами)
sudo aa-complain /usr/bin/pacman
sudo aa-complain /usr/bin/paru        # если есть /usr/bin/paru
# gcc, strip, ld, as, objcopy - часто вызываются во время компиляции.
sudo aa-complain /usr/bin/gcc
sudo aa-complain /usr/bin/strip
sudo aa-complain /usr/bin/ld.bfd      # или ld.lld
sudo aa-complain /usr/bin/as
sudo aa-complain /usr/bin/objcopy
```

> paru это обертка над pacman, оне будет наследовать разрешения. Можно создать ссылку на pacman для явного указания `ln -sf /etc/apparmor.d/usr.bin.makepkg /etc/apparmor.d/usr.bin.paru`.

Проверяем через `aa-status | grep complain` и тестируем через сборку из AUR `paru -S --noconfirm checkbashisms`.

Проверяем логи через `sudo aa-logprof`, он проанализирует записи аудита и предложит добавить разрешения. Простой вариант отвечать "allow" для разумных `read /usr, /var, /tmp, /proc`, `write $BUILDDIR, $PKGDEST`.

После того как сессия aa-logprof завершена, профили автоматически обновятся. Выглядеть он будет как-то так `/etc/apparmor.d/usr.bin.makepkg`:

```makepkg
abi <abi/4.0>,
include <tunables/global>

/usr/bin/makepkg {
  #include <abstractions/base>
  #include <abstractions/consoles>
  #include <abstractions/nameservice>

  # ACCESS: Разрешаем только нужные команды для сборки
  /usr/bin/bash   rix,
  /usr/bin/gcc    rix,
  /usr/bin/make   rix,
  /usr/bin/coreutils/** rix,
  /usr/bin/patch  rix,
  /usr/bin/pacman rix,

  # ACCESS: расширения для работы AUR:
  /usr/bin/bash     mr,
  /usr/bin/git      rix,
  /usr/bin/pacman   rix,
  /usr/bin/paru     rix,
  /usr/bin/sudo     rix,   # может быть, не обязательно

  # DENY: npm, bun, node, python, perl
  deny /usr/bin/npm   ix,
  deny /usr/bin/bun   ix,
  deny /usr/bin/node  ix,
  deny /usr/bin/python3 ix,
  deny /usr/bin/perl  ix,

  # Чтение системных библиотек
  /usr/lib/**  r,
  /usr/share/** r,

  # Работа с исходным кодом и пакетами
  /var/abs/**   rw,    # директория сборки
  /tmp/**       rwk,   # временные файлы часто
  /home/*/pkg/**            rw,   # если PKGDEST=/home/user/pkg
  /home/*/.cache/paru/clone/**  rw,   # типовое место для AUR
  /var/cache/pacman/pkg/**      rw,      # для установки зависимостей

  # DENY: запрет на запись в конфиденциальные файлы
  deny /**/.ssh/**         rw,
  deny /**/.gnupg/**       rw,
  deny /**/.config/**      rw,
  deny /etc/ssh/**         rw,

  # Необходимые привилегии для mkdir, mount (chroot)
  # Capabilities без sys_admin и bpf
  capability dac_override,
  capability setuid,
  capability setgid,
 
  # DENY:eBPF-rootkit: безвредная сборка не должна иметь такие возможности
  # capability sys_admin,
  # capability bpf,

  # Дочерние процессы (сборка)
  /usr/bin/gcc         rix,
  /usr/bin/ld.bfd      rix,
  /usr/bin/strip       rix,
  /usr/bin/objcopy     rix,
  /usr/bin/as          rix,

  #  # ACCESS: или разрешить сеть (wget/curl внутри makepkg)
  #  network inet stream,
  #  network inet6 stream,
  #  # DENY: или строго ограничить сеть
  #  deny network inet stream,
  #  deny network inet6 stream,
  # Если нужна — можно разрешить только для скачивания PKGBUILD через git
}
```

4. После создания профиля и проверки, что сборки работают его можно переключить в enforce:

```bash
sudo aa-enforce /usr/bin/makepkg
```

5. **На практике**: чтобы не собирать профили вручную для каждого пакета
Разработчики предлагают для AUR не писать профили вообще, а держать makepkg и gcc в complain. Это безопаснее, чем включать enforce и потом смотреть, как падает сборка.
- complain для: makepkg, pacman, gcc, strip, ld, as, objcopy.
- enforce профили для отдельных приложений: vesktop, telegram-desktop, etc.

**Приложения на которые не установлен запрет - разрешены**, то есть makepkg может использовать любой интерпретатор в системе (а может и установить через dependencies). Из-за этого прямой запрет работает как "угадайка".

Можно работать через "белый список", но он, вероятно, будет очень большой и сложно поддерживаемые, т.к. могут использовать различные команды в makepkg.

**Запрет сети** - запрещает загрузку, что может мешать нормальным пакетом, которые устанавливаются через curl, wget или через собственные репозитории.

**Запуск в изолированной среде** можно использовать контейнеры, chroot или [Bubblewrap - low-level unprivileged sandboxing, used by flatpak / github.com](https://github.com/containers/bubblewrap).

6. Проверка итогового состояния
```bash
sudo aa-status  # enforced и complain профили
sudo journalctl -u auditd --since "1 hour ago" | grep DENIED  # если в enforce есть запреты
```
Если в enforce какие-то пакеты не собираются переводим в complain и проверяем что не так:

```bash
sudo aa-complain /usr/bin/makepkg
```

## References
1. [AppArmor Documentation / apparmor.net](https://www.apparmor.net)

