#!/bin/bash
while true; do
    echo "Welcome to the Inventory Manager!";
    echo "==============================="
    echo "1. View Inventory"
    echo "2. Add a New Product"
    echo "3. Update Stock"
    echo "4. Search Products"
    echo "5. View items(Low-Stock)"
    echo "6. Record Item Sale"
    echo "7. Delete a Product"
    echo "8. Save/Load Inventory from CSV"
    echo "9. Print Inventory Report"
    echo "0. Exit Menu"
    read -p "Enter your choice: " menu

    case "$menu" in
    1) view_inv ;;
    2) add_product ;;
    3) update_stock ;;
    4) search_products ;;
    5) low_stock_items ;;
    6) record_sale ;;
    7) delete_product ;;
    8) save_load_inv_csv ;;
    9) inv_report ;;
    0) echo "Exiting the menu..."; break ;;
    *) echo "Invalid option. Try again" ;;
    esac
done