# Lilith Linux - Rust Alternatives Configuration
# This file documents the Rust-based replacements for traditional Linux utilities

## Coreutils Replacements (with GNU fallback)

| Traditional | Rust Alternative | Package | Notes |
|------------|------------------|---------|-------|
| ls | lsd | lsd-rs/lsd | Modern, colored ls |
| cat | bat | sharkdp/bat | Syntax highlighting |
| find | fd | sharkdp/fd | Faster find |
| grep | ripgrep | BurntSushi/ripgrep | Faster grep |
| du | dust | bootandy/dust | Pretty du |
| ps | procs | dalance/procs | Modern ps |
| top/htop | bottom | ctpbtm/bottom | System monitor |

## Additional Rust Tools

| Tool | Repository | Purpose |
|------|------------|---------|
| just | casey/just | Command runner |
| starship | starship/starship | Shell prompt |
| zoxide | ajeetdsouza/zoxide | Smarter cd |
| broot | Canop/broot | File tree navigation |
| navi | denisidoro/navi | Cheat sheet |
| bat | sharkdp/bat | cat with wings |
| exa | ogham/exa | Modern ls (older) |
| cargo-nextest | nextest | Faster test runner |
| diesel | diesel-rs/diesel | ORM |

## System Components (from lil-staRS.toml)

### Boot & Firmware
- oreboot - Rust boot firmware
- uefi-rs - UEFI in Rust
- r-efi - Rust EFI definitions
- sprout - Modern bootloader

### OS Components
- Theseus - Rust OS
- Redox - Rust OS
- Kerla - Linux-compatible Rust OS

### Desktop (COSMIC already Rust-based)
- libcosmic - Rust desktop toolkit
- cosmic-utils - COSMIC utilities

### AI/ML (for Lilim)
- Crane - LLM inference in Rust
- Candle - ML framework (Rust)
- vllm.rs - VLM in Rust
- candle-vllm - VLM in Candle

## Installation Priority

### Must Have (Installed by default)
1. bat, lsd, fd-find, ripgrep
2. just (command runner)
3. starship (prompt)

### Should Have (Recommended)
4. dust, procs, broot, navi
5. zoxide

### Nice to Have (Optional)
6. cargo tools (clippy, etc.)

## Fallback Strategy

All Rust alternatives have seamless fallback to GNU coreutils:

```bash
# In /etc/profile.d/lilith-rust-alternatives.sh
ls() {
    if command -v lsd &> /dev/null; then
        lsd "$@"
    else
        command ls "$@"
    fi
}
```

This ensures system reliability while providing modern UX.
