import pandas as pd
import sys

if len(sys.argv) != 3:
    print("Pas bon")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

df = pd.read_excel(input_file)

df.to_csv(output_file, index = False)
print("gud")