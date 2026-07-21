#!/bin/sh

apply_dns()
{
    NEW_DNS="${1:-1.1.1.1}"
    log_info "Setting temporary DNS to [$NEW_DNS]..."

    if [ -f /etc/resolv.conf ]; then
        cp /etc/resolv.conf /tmp/resolv.conf.bak 2>/dev/null
        echo "nameserver $NEW_DNS" > /etc/resolv.conf
        log_success "DNS changed to [$NEW_DNS]"
    fi
}

restore_dns()
{
    if [ -f /tmp/resolv.conf.bak ]; then
        mv /tmp/resolv.conf.bak /etc/resolv.conf 2>/dev/null
        log_info "Original DNS restored!"
    fi
}

dns_fix_menu()
{
    echo
    log_warn "DNS failure detected! Select a fallback DNS resolver :"
    echo "  1) Cloudflare (1.1.1.1)"
    echo "  2) Google (8.8.8.8)"
    echo "  3) Quad9 (9.9.9.9)"
    echo "  4) Skip"

    printf "  ⁉️ Choice : "
    read -r dns_choice </dev/tty

    case "$dns_choice" in
        1) apply_dns "1.1.1.1" ;;
        2) apply_dns "8.8.8.8" ;;
        3) apply_dns "9.9.9.9" ;;
        *) log_info "Skipping DNS fix!" ;;
    esac
}