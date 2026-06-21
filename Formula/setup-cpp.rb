class SetupCpp < Formula
  desc "C++ competitive programming setup for macOS (Homebrew GCC, bits/stdc++.h, debug tools)"
  homepage "https://github.com/will702/setup-cpp"
  url "https://github.com/will702/setup-cpp/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "7b9b7f31b674238b8ee39932163765fef10093adeaec0fc6969ff9631f6968ee"
  license "MIT"
  version "1.0.0"

  head "https://github.com/will702/setup-cpp.git", branch: "main"

  # GCC is required: Apple clang does not ship bits/stdc++.h
  depends_on "gcc"

  def install
    # CLI tools
    bin.install "cpc"
    bin.install "cprun"
    bin.install "cpnew"
    bin.install "setup-cpp"

    # Assets read by setup-cpp init and cpnew
    (share/"setup-cpp").install "debug.h"
    (share/"setup-cpp").install "template.cpp"
    (share/"setup-cpp/vscode-templates").install "vscode-templates/c_cpp_properties.json"
    (share/"setup-cpp/vscode-templates").install "vscode-templates/tasks.json"
  end

  # Basic smoke-test: help flag must exit 0
  test do
    assert_match "competitive-programming", shell_output("#{bin}/cpc -h")
    assert_match "cpnew", shell_output("#{bin}/setup-cpp -h")
  end

  def caveats
    <<~EOS
      Run once to complete setup (builds precompiled headers, configures VS Code):
        setup-cpp init

      After every 'brew upgrade gcc', rebuild the precompiled headers:
        setup-cpp update

      Quick start (from any directory):
        cpnew                    # create sol.cpp from template
        cpnew A B C D E          # create problem files for a contest
        cpnew --dir round A B C  # create round/ workspace with .vscode/
        cpc sol.cpp              # debug build (ASan + UBSan + dbg())
        cprun sol.cpp            # compile + run
        cpc -r sol.cpp           # release / submit build
    EOS
  end
end
