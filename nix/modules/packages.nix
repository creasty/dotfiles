# Command-line tools, pinned by flake.lock. Language toolchains are in their own modules.
{ pkgs, username, ... }:
{
  home-manager.users.${username}.home.packages = with pkgs; [
    awscli2 # Unified tool to manage your AWS services
    bat # Clone of cat(1) with syntax highlighting and Git integration
    cloc # Statistics utility to count lines of code
    ctags # Reimplementation of ctags(1)
    curl # Get a file from an HTTP, HTTPS or FTP server
    deno # Secure runtime for JavaScript and TypeScript
    difftastic # Diff that understands syntax
    direnv # Load/unload environment variables based on $PWD
    envchain # Secure your credentials in environment variables
    expect # Program that can automate interactive applications
    eza # Modern, maintained replacement for ls
    fd # Simple, fast and user-friendly alternative to find
    ffmpeg # Play, record, convert, and stream audio and video
    gh # GitHub command-line tool
    ghq # Remote repository management made easy
    git # Distributed revision control system
    git-filter-repo # Quickly rewrite git repository history
    git-lfs # Git extension for versioning large files
    gnupg # GNU Pretty Good Privacy (PGP) package
    graphviz # Graph visualization software from AT&T and Bell Labs
    hyperfine # Command-line benchmarking tool
    imagemagick # Tools and libraries to manipulate images in many formats
    jo # JSON output from a shell
    jq # Lightweight and flexible command-line JSON processor
    libwebp # Image format providing lossless and lossy compression for web images
    massren # Easily rename multiple files using your text editor
    ngrep # Network grep
    nkf # Network Kanji code conversion Filter (NKF)
    parallel # Shell command parallelization utility
    pastel # Command-line tool to generate, analyze, convert and manipulate colors
    peco # Simplistic interactive filtering tool
    procs # Modern replacement for ps written by Rust
    protobuf # Protocol buffers (Google's data interchange format)
    ripgrep # Search tool like grep and The Silver Searcher
    sd # Intuitive find & replace CLI
    tmux # Terminal multiplexer
    uv # Extremely fast Python package installer and resolver, written in Rust
    xh # Friendly and fast tool for sending HTTP requests
  ];
}
