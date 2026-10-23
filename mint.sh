#!/bin/bash
echo "Start Script"
echo "Is run as root?"
if (( $EUID != 0 )); then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

echo "helper funtions:"
confirm_action() {
  local prompt_message="$1"
  if [ "$PROMPT_BEFORE_ACTION" = false ]; then
    return 0
  fi
  read -p "[?] $prompt_message (y/N): " choice
  case "$choice" in
    [Yy]* ) return 0 ;;
    * ) return 1 ;;
  esac
}


interactive_account_manager() {
  while true; do
    echo ""
    echo "=========================================="
    echo "      Linux Mint User Account Manager     "
    echo "=========================================="
    echo "1) Create a new user account"
    echo "2) Modify an existing account"
    echo "3) Delete an account"
    echo "4) Exit"
    read -rp "Select an option [1-4]: " ACTION

    case "$ACTION" in
      1)
        read -rp "Enter new username: " USERNAME
        if [ -z "$USERNAME" ]; then
          echo "Error: Username cannot be empty."
          continue
        fi

        if id "$USERNAME" &>/dev/null; then
          echo "Error: User '$USERNAME' already exists."
          continue
        fi

        # Create user with a standard home directory and bash shell
        useradd -m -s /bin/bash "$USERNAME"
        echo "Account '$USERNAME' successfully created."

        # Set initial password
        read -rp "Set a password now? (y/n): " SET_PASS
        if [[ "$SET_PASS" =~ ^[Yy]$ ]]; then
          passwd "$USERNAME"
        fi

        # Account Type (Admin vs Regular User)
        read -rp "Grant Administrator privileges (add to sudo group)? (y/n): " IS_ADMIN
        if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
          usermod -aG sudo "$USERNAME"
          echo "User '$USERNAME' added to the 'sudo' group (Admin)."
        else
          echo "User '$USERNAME' configured as a regular user."
        fi

        # Password Expiration / Force Change
        read -rp "Force user to change password on next login? (y/n): " FORCE_EXPIRE
        if [[ "$FORCE_EXPIRE" =~ ^[Yy]$ ]]; then
          chage -d 0 "$USERNAME"
          echo "Password set to expire immediately on next login."
        fi

        # Account Expiration Date
        read -rp "Set account expiration date? (YYYY-MM-DD or leave blank for none): " EXP_DATE
        if [ -n "$EXP_DATE" ]; then
          chage -E "$EXP_DATE" "$USERNAME"
          echo "Account set to expire on $EXP_DATE."
        fi
        ;;

      2)
        read -rp "Enter username to modify: " USERNAME
        if ! id "$USERNAME" &>/dev/null; then
          echo "Error: User '$USERNAME' does not exist."
          continue
        fi

        # Modify Role
        read -rp "Modify Admin status? (1: Make Admin, 2: Remove Admin, 3: Skip): " ADMIN_CHOICE
        case "$ADMIN_CHOICE" in
          1)
            usermod -aG sudo "$USERNAME"
            echo "Granted Admin privileges."
            ;;
          2)
            gpasswd -d "$USERNAME" sudo &>/dev/null || true
            echo "Removed Admin privileges."
            ;;
          *)
            echo "Skipped Admin status change."
            ;;
        esac

        # Password Change
        read -rp "Change password? (y/n): " CHG_PASS
        if [[ "$CHG_PASS" =~ ^[Yy]$ ]]; then
          passwd "$USERNAME"
        fi

        # Force Password Change
        read -rp "Force password change on next login? (y/n): " FORCE_EXPIRE
        if [[ "$FORCE_EXPIRE" =~ ^[Yy]$ ]]; then
          chage -d 0 "$USERNAME"
          echo "Password forced to expire on next login."
        fi

        # Expiration Date
        read -rp "Set/Update account expiration date (YYYY-MM-DD or blank to skip): " EXP_DATE
        if [ -n "$EXP_DATE" ]; then
          chage -E "$EXP_DATE" "$USERNAME"
          echo "Account expiration set to $EXP_DATE."
        fi
        ;;

      3)
        read -rp "Enter username to delete: " USERNAME
        if ! id "$USERNAME" &>/dev/null; then
          echo "Error: User '$USERNAME' does not exist."
          continue
        fi

        read -rp "Delete user's home directory and files? (y/n): " REMOVE_HOME
        if [[ "$REMOVE_HOME" =~ ^[Yy]$ ]]; then
          userdel -r "$USERNAME"
          echo "User '$USERNAME' and home directory removed."
        else
          userdel "$USERNAME"
          echo "User '$USERNAME' removed (home directory preserved)."
        fi
        ;;

      4)
        echo "Exiting account manager."
        exit 0
        ;;

      *)
        echo "Invalid choice. Please select 1, 2, 3, or 4."
        ;;
    esac
  done
}

interactive_account_manager
