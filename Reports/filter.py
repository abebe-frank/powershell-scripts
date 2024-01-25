import os
import pandas as pd

#add the file path
userdata_path = ' '
mailbox_path= ' '

# Assuming users is your DataFrame with 'User principal name' and 'Licenses' columns
users = pd.read_csv(userdata_path)

# Load the CSV file into a DataFrame
df = pd.read_csv(mailbox_path)

def convert_to_bytes(size_str):
    # Extract numeric values and unit using regular expression
    match = re.match(r'([\d.]+)\s*([KMGTPEZY]?B)', size_str)
    
    if match:
        value, unit = match.groups()
        value = float(value.replace(',', ''))
        
        # Convert to bytes
        if unit == 'KB':
            value *= 1024
        elif unit == 'MB':
            value *= 1024 ** 2
        elif unit == 'GB':
            value *= 1024 ** 3
        elif unit == 'TB':
            value *= 1024 ** 4
        elif unit == 'PB':
            value *= 1024 ** 5
        elif unit == 'EB':
            value *= 1024 ** 6
        elif unit == 'ZB':
            value *= 1024 ** 7
        elif unit == 'YB':
            value *= 1024 ** 8

        return int(value)
    else:
        return None

# Iterate through unique user principal names
for user_principal_name in users['User principal name'].unique():
    # Use boolean indexing to get the 'Licenses' value for the current user principal name
    licenses_value = users.loc[users['User principal name'] == user_principal_name, 'Licenses'].iloc[0]

    # Filter the DataFrame based on the current user_principal_name
    filtered_df = df[df['Primary SMTP address'].isin([user_principal_name])]

    # Select specific columns in the filtered DataFrame
    filtered_df = filtered_df[['Display Name','Primary SMTP address', 'TotalItemSize','ProhibitSendReceiveQuota-In-MB','ArchiveQuota','ArchiveTotalItemSize','ArchiveState']]

    # Add the 'Licenses' column with the obtained value
    filtered_df['Licenses'] = licenses_value

    #Apply the conversion function to the 'TotalItemSize' column
    used_size = filtered_df['TotalItemSize'].apply(convert_to_bytes)
    alocatedsize = filtered_df['ProhibitSendReceiveQuota-In-MB'].apply(convert_to_bytes)
    perc_used_size = round((used_size * 100 / alocatedsize),2)

    filtered_df['Percentage Used'] = perc_used_size


    # Save the filtered DataFrame to a CSV file
    filtered_df.to_csv('filtered_mailboxsize.csv', mode='a', header=not os.path.exists('filtered_mailboxsize.csv'), index=False)

    print(f"Processed user: {user_principal_name}")

print("Done")
