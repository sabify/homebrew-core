class Nvc < Formula
  desc "VHDL compiler and simulator"
  homepage "https://github.com/nickg/nvc"
  url "https://github.com/nickg/nvc/releases/download/r1.7.0/nvc-1.7.0.tar.gz"
  sha256 "bc10ec3777b457582a66bb94f97c614d8d83956547aee4c658402da6e2474b32"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 arm64_monterey: "b2371ba0d077946c69d5c14c8314d2a63683c94257aff81d9c1c5997d5f4e329"
    sha256 arm64_big_sur:  "e3defcbfdbb1793c8d65eedf1e1112f970fa6342a3087bd87658be0b73f2d3a8"
    sha256 monterey:       "b463ff4781f3bd1268e2188f78ebc808198e85bc80404287f230384ee00787ed"
    sha256 big_sur:        "322252e7cdad7ff41a870942d04c5831c9db34f26446fa1b5bfe32208370c62a"
    sha256 catalina:       "29b35a7c9107639a318c57220d789c55cbe149f34a233997d34e05d60ed46ee2"
    sha256 x86_64_linux:   "b5bae3a503a28b18228332204768d41fd9e6afebfa5a032cb8978b7581ec37c5"
  end

  head do
    url "https://github.com/nickg/nvc.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "check" => :build
  depends_on "pkg-config" => :build
  depends_on "llvm"

  uses_from_macos "flex" => :build

  fails_with gcc: "5" # LLVM is built with GCC

  resource "homebrew-test" do
    url "https://github.com/suoto/vim-hdl-examples.git",
        revision: "fcb93c287c8e4af7cc30dc3e5758b12ee4f7ed9b"
  end

  patch do
    # Fix build with glibc < 2.36
    # Remove in the next release
    on_linux do
      url "https://github.com/nickg/nvc/commit/3f1a495360d4c97bf6537e62eb77c1269297dcb2.patch?full_index=1"
      sha256 "d5bda0f89c346f618b9bc5ce96095be5bb9eb8e0fec3caea4ebddfe1ae2dee23"
    end
  end

  def install
    system "./autogen.sh" if build.head?

    # Avoid hardcoding path to the `ld` shim.
    inreplace "configure", "#define LINKER_PATH \\\"$linker_path\\\"", "#define LINKER_PATH \\\"ld\\\"" if OS.linux?

    # In-tree builds are not supported.
    mkdir "build" do
      system "../configure", "--with-llvm=#{Formula["llvm"].opt_bin}/llvm-config",
                             "--prefix=#{prefix}",
                             "--with-system-cc=#{ENV.cc}",
                             "--disable-silent-rules"
      inreplace ["Makefile", "config.h"], Superenv.shims_path/ENV.cc, ENV.cc
      ENV.deparallelize
      system "make", "V=1"
      system "make", "V=1", "install"
    end
  end

  test do
    resource("homebrew-test").stage testpath
    system bin/"nvc", "-a", testpath/"basic_library/very_common_pkg.vhd"
  end
end
