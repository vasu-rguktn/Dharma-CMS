import pandas as pd
import os

excel_path = r'c:\Users\APSSDC\Desktop\main\Dharma-CMS\police-frontend\assets\Data\Revised AP Police Organisation 31-01-26.xlsx'

try:
    print(f"Reading {excel_path}...")
    # Load the excel file
    df = pd.read_excel(excel_path)
    
    # Print basic info to understand structure
    print("\n--- COLUMNS ---")
    print(df.columns.tolist())
    
    print("\n--- FIRST 5 ROWS ---")
    print(df.head().to_string())
    
    print("\n--- NA Check ---")
    print(df.isna().sum())

except ImportError:
    print("Error: pandas or openpyxl not installed. Please install them using: pip install pandas openpyxl")
except Exception as e:
    print(f"Error reading Excel: {e}")
