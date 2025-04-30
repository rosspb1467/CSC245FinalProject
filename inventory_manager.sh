#!/bin/bash
# Displays an error when no argument is given
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments given."
    exit 1
fi

file="$1"
# Checks if a csv or txt file was inputted as the argument
if [[ "$file" != *.csv && "$file" != *.txt ]]; then
    echo "Error: Only .csv or .txt files allowed"
    exit 1
fi

# If a file is given as an argument doesn't exist, create it
if [ ! -f "$file" ]; then
    echo "Name,ID,Quantity,Price" > "$file"
    echo "Created new file: $file"
    echo "Using new file: $file"
fi

# Displays the current inventory of products
view_inv() {
    echo
    echo "Current Inventory"
    echo "==============================="
    column -s, -t < "$file"
    echo "==============================="
}

# Function to add new products into the inventory with headings
add_product() {
    while true; do
        read -p "Enter product name: " prod
        # Validate product names with POSIX Expressions allowing special characters
        if [[ "$prod" =~ ^[a-zA-Z0-9[:space:][:punct:]]+$ ]]; then
            # Checks if product already exists
            if grep -iq "^$prod," "$file"; then
                echo "Product $prod already exists. Try another."
            else
                break
            fi
        else
            echo "Invalid name."
        fi
    done
    while true; do
        read -p "Enter Product ID: " id
        # Validate product IDs
        if [[ "$id" =~ ^[A-Za-z0-9_-]+$ ]]; then
            # Checks if ID inputted already exists
            if awk -F',' -v id="$id" '$2 == id {found=1} END {exit !found}' "$file"; then
                echo "ID $id already exists. Try another."
            else
                break
            fi
        else
            echo "Invalid ID."
        fi
    done
    while true; do
        read -p "Enter quantity: " qty
        # Validate quantity input allowing only numbers
        if [[ "$qty" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid quantity."
        fi
    done
    while true; do
        read -p "Enter price: " price
        # Validate price input allowing only numbers and must be decimal
        if [[ "$price" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
            break
        else
            echo "Invalid price."
        fi
    done

    # Adds products to the CSV file with headings
    echo "$prod,$id,$qty,$price" >> "$file"
    echo "Added product: $prod with ID of $id with amount of $qty priced at $price"
    echo "==============================="
}

# Function that updates the stock quantity for a product
update_stock() {
    while true; do
        read -p "Enter product ID to update stock: " prodID
        # Validate product ID input only allowing numbers
        if [[ "$prodID" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid Product ID. Please try again."
        fi
    done
    # Checks if product ID exists
    if grep -q ",$prodID," "$file"; then
        while true; do
            read -p "Enter new amount: " stock
            if [[ "$stock" =~ ^[0-9]+$ ]]; then
                break
            else
                echo "Invalid amount. Only numbers allowed."
            fi
        done
        # Updates product quantity by replacing the old qauntity with a new one
        sed -i "/,$prodID,/s/^\([^,]*,[^,]*,\)[^,]*/\1$stock/" "$file"
        echo "Product ID $prodID's quantity has been updated to $stock."
    else
        echo "Product ID not found."
    fi
    echo "==============================="
}

# Function that searchs for products by name or ID
search_products() {
    read -p "Enter product ID or name to search: " search
    echo
    echo "Search Results"
    echo "==============================="
    # Search is based on whether input is a number or text for ID or name
    if [[ "$search" =~ ^[0-9]+$ ]]; then
        match=$(awk -F',' -v id="$search" '$2 == id {print}' "$file")
    else
        match=$(awk -F',' -v name="$search" 'tolower($1) == tolower(name) {print}' "$file")
    fi
    # If search finds a match, displays the product in a column with headings
    if [ -n "$match" ]; then
        {
            echo "Name,ID,Quantity,Price"
            echo "$match"
        } | column -s, -t
    else
        echo "Product not found."
    fi
    echo "==============================="
}

# Function that displays products that are low on stock
low_stock_items() {
    read -p "Enter the stock threshold: " threshold
    echo
    if [[ "$threshold" =~ ^[0-9]+$ ]]; then
        echo "Products with stock below $threshold"
        echo "==============================="
        {
            echo "Name,ID,Quantity,Price"
            tail -n +2 "$file" | awk -F',' -v thresh="$threshold" '$3 < thresh {print $0}'
        } | column -s, -t
    else
        echo "Invalid input."
    fi
    echo "==============================="
}

# Function that records a sale and updates the stock of whatever product was sold
record_sale() {
    while true; do
        read -p "Enter product ID for sale: " sale
        # Validate prodID input allowing only numbers
        if [[ "$sale" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid Product ID. Please try again."
        fi
    done
    # Checks if product exists
    if grep -q ",$sale," "$file"; then
        while true; do
            read -p "Enter quantity sold: " sold
            if [[ "$sold" =~ ^[0-9]+$ ]]; then
                # Extract the current quantity of product inputted
                IFS=',' read -r name id_found quantity price <<< "$(grep ",$sale," "$file")"
                # Checks if product has enough current stock
                if [ "$sold" -le "$quantity" ]; then
                    new_quantity=$((quantity - sold))
                    sed -i "/,$sale,/c\\$name,$id_found,$new_quantity,$price" "$file"
                    echo "Sale recorded: Sold $sold units of $name."
                    break
                else
                    echo "Error: Not enough stock available."
                fi
            else
                echo "Invalid quantity. Please try again."
            fi
        done
    else
        echo "Product ID not found."
    fi
    echo "==============================="
}

# Function that deletes a product from the inventory
delete_product() {
    while true; do
        read -p "Enter product ID to delete: " id
        # Validate prodID input allowing only numbers
        if [[ "$id" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid ID."
        fi
    done
    # Checks if product exists
    if grep -q ",$id," "$file"; then
        while true; do
            read -p "Are you sure you want to delete this product? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sed -i "/,$id,/d" "$file"
                echo "Product deleted successfully."
                break
            elif [[ "$confirm" =~ ^[Nn]$ ]]; then
                echo "Deletion canceled."
                break
            else
                echo "Invalid input. Please try again."
            fi
        done
    else
        echo "Product ID not found."
    fi
    echo "==============================="
}

# Function that allows saving of current inventory to a backup file or load from an existing CSV file
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
                # Only allows .csv files to be inputted
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

# Function that allows exporting of inventory report to a text or csv file
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

# Main Menu Choices
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