# reference https://github.com/burhancodes/fagram-bin/blob/main/PKGBUILD
# Maintainer: TakiMoysha <mpwema782@gmail.com>
pkgname=kafkio
pkgver=0.1.0
pkgrel=1
pkgdesc="The Fast, Easy Apache Kafka™ GUI, for Engineers and Administrators"
license=('Donationware')
arch=('x86_64')
url="https://kafkio.com/download/kafkio/$pkgver/KafkIO-linux-$pkgver-x64.tar.gz"
source=("kafkaio.tar.gz::https://example.com/releases/kafkaio-linux-amd64.tar.gz")
sha256sums=("SKIP")

depends=()

prepare() {
    cd "$srcdir"
    # Можно распаковать вручную, если нужно что-то модифицировать
    tar -xzf kafkaio.tar.gz
}

package() {
    cd "$srcdir"

    # Создаём директорию для бинарника
    install -Dm755 bin/KafkIO "$pkgdir/usr/bin/kafkaio"

    # Если есть дополнительные файлы (man, docs и т.д.)
    # Например, документация:
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}

package() {
    # Распаковать архив
    tar -xzf "${srcdir}/${pkgname}-${pkgver}.tar.gz"

    # Установить файлы
    cp -r "${pkgname}-${pkgver}/" "${pkgdir}/opt/${pkgname}/"
}


post_install() {
    echo "==> KafkaIO установлен. Запустите 'kafkaio --help' для начала."
}

