import os
import pandas as pd

# Assuming users is your DataFrame with 'User principal name' and 'Licenses' columns
users = pd.read_csv('users.csv')

# Load the CSV file into a DataFrame
df = pd.read_csv('REPORTTEST.CSV')

# Iterate through unique user principal names
for user_principal_name in users['User principal name'].unique():
    # Use boolean indexing to get the 'Licenses' value for the current user principal name
    licenses_value = users.loc[users['User principal name'] == user_principal_name, 'Licenses'].iloc[0]

    # Filter the DataFrame based on the current user_principal_name
    filtered_df = df[df['Primary SMTP address'].isin([user_principal_name])]

    # Select specific columns in the filtered DataFrame
    filtered_df = filtered_df[['Primary SMTP address', 'TotalItemSize']]

    # Add the 'Licenses' column with the obtained value
    filtered_df['Licenses'] = licenses_value

    # Save the filtered DataFrame to a CSV file
    filtered_df.to_csv('filtered_mailboxsize.csv', mode='a', header=not os.path.exists('filtered_mailboxsize.csv'), index=False)

    print(f"Processed user: {user_principal_name}")

print("Done")
