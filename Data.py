minutes = int(input("Enter minutes: "))

hours = minutes // 60
remaining = minutes % 60

print(f"{hours} hrs {remaining} minutes")