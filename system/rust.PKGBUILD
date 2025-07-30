pkgname="example_app"
pkgver=0.1.0
pkgrel=1
pkgdesc="Short description about application"
arch=("x86_64")
url="https://github.com/takimoysha/app_repository"
license=("MIT" or "Apache-2.0" or "GPL3")
depends=("glibc")
makedepends=("rust" "cargo" "git")
provides=("$pkgname") # working with conflicts
conflicts=("$pkgname") # working with conflicts
source=("git+https://github.com/takimoysha/app_repository#tag=v$pkgver")
sha256sums=("SKIP") # если не знаешь хеш

# Optional: if cargo.toml contains not equal pkgver
# pkgver() {
#  cd "$srcdir/app_repository"
#  git describe --tags | sed 's/^v//'
#}

build() {
  cd "$srcdir/app_repository"
  cargo build --release --frozen
}

check() {
  cd "$srcdir/app_repository"
  cargo test --release --frozen
}

package() {
  cd "$srcdir/app_repository"

  install -Dm755 "target/release/app_name" "$pkgdir/usr/bin/pkgname"

  # Optional: install man page
  # install -Dm644 "doc/$pkgname.1" "$pkgdir/usr/share/man/man1/$pkgname.1"

  # Optional: install autocompletion
  # install -Dm644 "contrib/completions/$pkgname.bash" "$pkgdir/usr/share/bash-completion/completions/$pkgname"

  # Optional: install license
  # install -Dm644 "LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  
}
