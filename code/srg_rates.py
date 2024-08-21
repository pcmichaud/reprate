import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


df = pd.read_excel('../data/RR_original.xls',sheet_name='GIS_rate')

claim_ages = [66,70]
labels = ['65-69','70-74']
plt.figure()
for i,c in enumerate(claim_ages):
    tab = df[(df.AC==60) & (df.age==c)]
    plt.plot(tab['decile'],tab['stat'],label=labels[i])
plt.legend()
plt.xlabel('decile du revenu age 55-59')
plt.ylabel('Gain net par dollar pour report de la rente')
plt.savefig('../figures/claw_decile.png',dpi=1200)
plt.show()

print(df.head())
