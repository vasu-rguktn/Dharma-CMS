import pandas as pd
import sys

# Set display options to show all columns and more rows
pd.set_option('display.max_rows', 200)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', 1000)

excel_path = r'c:\Users\APSSDC\Desktop\main\Dharma-CMS\police-frontend\assets\Data\Revised AP Police Organisation 31-01-26.xlsx'

try:
    print(f"Reading {excel_path}...")
    df = pd.read_excel(excel_path)
    
    print("\n--- Rows 0-100 ---")
    print(df.iloc[0:100].to_string())
    
except Exception as e:
    print(f"Error: {e}")
