import sys

file_name = sys.argv[1]
with open(file_name) as f:
    source_code = f.read()
    hex_encoded = source_code.encode().hex()
    print(hex_encoded)