# CSC245FinalProject
This is a Bash-based Inventory Management Tool designed for a fictional small convenience store chain.
The tool allows store employees to easily view, add, update, delete, search, and monitor product inventory through a simple command-line interface.
It also supports saving, loading, and exporting inventory data via CSV and text reports.

To run this script, download the inventory_manager.sh bash script and load it in your preferred Linux distribution terminal.
To run it properly, run the code snippet below to make it executable:
```
chmod +x inventory_manager.sh
```
Then run the script with either the sample csv file from the repo or you can simply create a new one:
```
./inventory_manager.sh inventory.csv
```
```
./inventory_manager.sh myInventory.csv
```

# Sample Outputs
Main Menu
```bash
===============================
Welcome to the Inventory Manager!
===============================
1. View Inventory
2. Add a New Product
3. Update Stock
4. Search Products
5. View items (Low-Stock)
6. Record Item Sale
7. Delete a Product
8. Save/Load Inventory from CSV
9. Print Inventory Report
0. Exit Menu
```
Low-Stock Report Example
```bash
Products with stock below 9
===============================
Name          ID         Quantity   Price
Test          1          1          $9.99      
Arizona Tea   5          1          $0.99
Samsung TV    7          4          $300.00
Dr.Pepper     10         8          $1.99
===============================
```
Record Sale Example:
```bash
Enter your choice: 6 (Record Item Sale Choice)
Enter product ID for sale: 6
Enter quantity sold: 15
Sale recorded: Sold 15 units of Avocados.
```
