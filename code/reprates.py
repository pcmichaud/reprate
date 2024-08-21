import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


df = pd.read_excel('../data/RR_original.xls',sheet_name='RR_decile_id')

claim_ages = [60,65]
age = 70

plt.figure()
for c in claim_ages:
    tab = df[(df.AC==c) & (df.age==age)]
    plt.plot(tab['decile'],tab['stat'],label=str(c))
plt.legend()
plt.xlabel('decile du revenu age 55-59')
plt.ylabel('taux de remplacement')
plt.savefig('../figures/reprates_decile.png',dpi=1200)
plt.show()

print(df.head())
