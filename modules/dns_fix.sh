#!/bin/sh

BACKUP_DNS_FILE="/etc/resolv.conf.daypass.bak"

apply_dns()
{
    NEW_DNS="${1:-1.1.1.1}"
    log_info "Setting temporary DNS to [$NEW_DNS] ..."

    if [ -f /etc/resolv.conf ]; then

        if [ ! -f "$BACKUP_DNS_FILE" ]; then
            cp /etc/resolv.conf "$BACKUP_DNS_FILE" 2>/dev/null
            log_success "Original DNS backed up to [$BACKUP_DNS_FILE]"
        fi

        # اعمال DNS جدید
        echo "nameserver $NEW_DNS" > /etc/resolv.conf
        log_success "DNS changed to [$NEW_DNS]"
    fi
}

restore_dns()
{
    if [ -f "$BACKUP_DNS_FILE" ]; then
        cp "$BACKUP_DNS_FILE" /etc/resolv.conf 2>/dev/null
        rm -f "$BACKUP_DNS_FILE" 2>/dev/null
        log_success "Original DNS restored successfully!"
    else
        log_warn "No DNS backup found to restore!"
    fi
}

dns_fix_menu()
{
    echo
    log_warn "DNS failure detected! Select an action :"
    echo "  1) Cloudflare (1.1.1.1)"
    echo "  2) Google (8.8.8.8)"
    echo "  3) Quad9 (9.9.9.9)"
    
    if [ -f "$BACKUP_DNS_FILE" ]; then
        echo "  4) Restore Original DNS (Reset to Default)"
        echo "  5) Skip"
    else
        echo "  4) Skip"
    fi

    printf "  ⁉️ Choice : "
    read -r dns_choice </dev/tty

    case "$dns_choice" in
        1) apply_dns "1.1.1.1" ;;
        2) apply_dns "8.8.8.8" ;;
        3) apply_dns "9.9.9.9" ;;
        4) 
            if [ -f "$BACKUP_DNS_FILE" ]; then
                restore_dns
            else
                log_info "Skipping DNS fix!"
            fi
            ;;
        *) log_info "Skipping DNS fix!" ;;
    esac
}