class LlvmBolt < Formula
  desc "Post-link optimizer developed to speed up large applications"
  homepage "https://llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-project-14.0.6.src.tar.xz"
  sha256 "8b3cfd7bc695bd6cea0f37f53f0981f34f87496e79e2529874fd03a2f9dd3a8a"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"
  livecheck do
    url :stable
    regex(/^llvmorg[._-]v?(\d+(?:\.\d+)+)$/i)
  end
  bottle do
    sha256 cellar: :any_skip_relocation, x86_64_linux: "e6b64382ae42ebcb47139791ca2a8628c18110f3d9cb27eed19ab963762d1ed2"
  end

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "llvm" => :test
  depends_on :linux

  def install
    args = %w[
      -DLLVM_TARGETS_TO_BUILD=X86
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_ASSERTIONS=ON
      -DLLVM_ENABLE_PROJECTS=bolt
      -DLLVM_INCLUDE_TESTS=OFF
      -DBOLT_INCLUDE_TESTS=OFF
    ]

    mkdir buildpath/"build" do
      system "cmake", "-G", "Unix Makefiles", *args, *std_cmake_args, "../llvm"
      system "cmake", "--build", ".", "--target", "install-llvm-bolt",
             "install-perf2bolt", "install-merge-fdata", "install-llvm-boltdiff", "install-bolt_rt"
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello World!" << std::endl;
        return 0;
      }
    EOS

    system "#{Formula["llvm"].opt_bin}/clang++", "-v",
           "-std=c++11", "-Wl,--emit-relocs", "test.cpp", "-o", "test"

    system "#{bin}/llvm-bolt", "test", "--instrument", "-o", "test.inst", "--instrumentation-file=prof.fdata"

    system "./test.inst"

    system "#{bin}/llvm-bolt", "test", "-o", "test.bolt", "--data=prof.fdata", "--reorder-blocks=ext-tsp",
           "--reorder-functions=hfsort", "--split-functions=3", "--split-all-cold", "--split-eh", "--dyno-stats"

    assert_equal "Hello World!", shell_output("./test.bolt").chomp
  end
end
