#!/bin/bash
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments given."
    exit 1
fi

file="$1"
if [ ! -f "$file" ]; then
    echo "Name,ID,Quantity,Price" > "$file"
    echo "Created new file: $file"
    echo "Using new file: $file"
fi

view_inv() {
    echo
    echo "Current Inventory"
    echo "==============================="
    column -s, -t < "$file"
    echo "==============================="
}

add_product() {
    while true; do
        read -p "Enter product name: " prod
        if [[ "$prod" =~ ^[a-zA-Z0-9]+( [a-zA-Z]+)*$ ]]; then
            if grep -iq "^$prod," "$file"; then
                echo "Product $prod already exists. Try another"
            else
                break
            fi
        else
            echo "Invalid name."
        fi
    done
    while true; do
        read -p "Enter Product ID: " id
        if [[ "$id" =~ ^[A-Za-z0-9_-]+$ ]]; then
            if grep -iq "^$id," "$file"; then
                echo "ID $id already exists. Try another."
            else
                break
            fi
        else
            echo "Invalid ID"
        fi
    done
    while true; do
        read -p "Enter quantity: " qty
        if [[ "$qty" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid quantity."
        fi
    done
    while true; do
        read -p "Enter price: " price
        if [[ "$price" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
            break
        else
            echo "Invalid price."
        fi
    done

    echo "$prod,$id,$qty,$price" >> "$file"
    echo "Added product: $prod with ID of $id with amount of $qty priced at $price"
    echo "==============================="
}

update_stock() {
    read -p "Enter product ID to update stock: " prodID
    if grep -q ",$prodID," "$file"; then
        while true; do
            read -p "Enter new amount: " stock
            if [[ "$stock" =~ ^[0-9]+$ ]]; then
                break
            else
                echo "Invalid amount."
            fi
        done
        sed -i "/,$prodID,/s/^\([^,]*,[^,]*,\)[^,]*/\1$stock/" "$file"
        echo "Product ID $prodID's quantity has been updated to $stock."
    else
        echo "Product ID $prodID not found."
    fi
    echo "==============================="
}

search_products() {
    read -p "Enter product ID or name to search: " search
    echo "Search Results"
    echo "==============================="
    if [[ "$search" =~ ^[0-9]+$ ]]; then
        match=$(awk -F',' -v id="$search" '$2 == id {print}' "$file")
    else
        match=$(awk -F',' -v name="$search" 'tolower($1) == tolower(name) {print}' "$file")
    fi

    if [ -n "$match" ]; then
        echo "$match" | column -s, -t
    else
        echo "Product not found."
    fi
    echo "==============================="  
}

low_stock_items() {
    read -p "Enter the stock threshold: " threshold
    if [[ "$threshold" =~ ^[0-9]+$ ]]; then
        echo "Products with stock below $threshold"
        echo "==============================="
        printf "%-7s %-7s %-10s %-10s\n" "Name" "ID" "Quantity" "Price"
        tail -n +2 "$file" | while IFS=',' read -r name id quantity price; do
            quantity=${quantity//[$'\r\n ']/}
            if [[ "$quantity" =~ ^[0-9]+$ && "$quantity" -lt "$threshold" ]]; then
                printf "%-7s %-7s %-10s \$%-10s\n" "$name" "$id" "$quantity" "$price"
            fi
        done
    else
        echo "Invalid input."
    fi
    echo "==============================="
}

record_sale() {
    read -p "Enter product ID for sale: " sale
    if grep -q ",$sale," "$file"; then
        read -p "Enter quantity sold: " sold
        if [[ "$sold" =~ ^[0-9]+$ ]]; then
            IFS=',' read -r name id_found quantity price <<< "$(grep ",$sale," "$file")"
            if [ "$sold" -le "$quantity" ]; then
                new_quantity=$((quantity - sold))
                sed -i "/,$sale,/c\\$name,$id_found,$new_quantity,$price" "$file"
                echo "Sale recorded: Sold $sold units of $name."
            else
                echo "Error: Not enough stock available."
            fi
        else
            echo "Invalid quantity."
        fi
    else
        echo "Product ID not found."
    fi
    echo "==============================="
}

delete_product() {
    echo
    read -p "Enter product ID to delete: " id
    if grep -q ",$id," "$file"; then
        read -p "Are you sure you want to delete this product? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            sed -i "/,$id,/d" "$file"
            echo "Product deleted successfully."
        else
            echo "Deletion canceled."
        fi
    else
        echo "Product ID not found."
    fi
    echo "==============================="
}

save_load_inv_csv() {
    echo "Save/Load Inventory"
    echo "==============================="
    while true; do
        echo "1. Save Inventory"
        echo "2. Load Inventory"
        read -p "Enter your choice (1 or 2): " option
        if [ "$option" == "1" ]; then
            cp "$file" "inventory_backup.csv"
            echo "Inventory saved as inventory_backup.csv."
            break
        elif [ "$option" == "2" ]; then
            while true; do
                read -p "Enter the CSV filename to load from: " loadfile
                if [[ "$loadfile" == *.csv ]]; then
                    if [ -f "$loadfile" ]; then
                        cp "$loadfile" "$file"
                        echo "Inventory loaded from $loadfile."
                        break 2
                    else
                        echo "File '$loadfile' not found. Please try again."
                    fi
                else
                    echo "Invalid file type. Only .csv files are allowed"
                fi
            done
        else
            echo "Invalid option. Please try again."
        fi
    done
    echo "==============================="
}

inv_report() {
    while true; do
        read -p "Would you like to export the current inventory as a report file? (y/n): " export_choice
        if [[ "$export_choice" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Invalid input."
        fi
    done
    if [[ "$export_choice" =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter 1 for Text or 2 for CSV file: " file_type
            if [ "$file_type" == "1" ] || [ "$file_type" == "2" ]; then
                break
            else
                echo "Invalid selection."
            fi
        done
        read -p "Enter filename to save: " filename
        if [ "$file_type" == "1" ]; then
            column -s, -t < "$file" > "${filename}.txt"
            echo "Inventory exported to ${filename}.txt"
        else
            cp "$file" "${filename}.csv"
            echo "Inventory exported to ${filename}.csv"
        fi
    else
        echo "Export cancelled."
    fi
    echo "==============================="
}

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