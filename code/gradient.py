import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


df = pd.read_excel('../data/income_gradient.xlsx')

df['se'] = - df['se']
df['ci_up'] = df['d'] + 1.96 * df['se']
df['ci_lo'] = df['d'] - 1.96 *df['se']
print(df.head())

plt.figure()
plt.plot(df['v'],df['d'],color='green')
plt.plot(df['v'],df['ci_lo'],linestyle='dashed',color='blue')
plt.plot(df['v'],df['ci_up'],linestyle='dashed',color='blue')
plt.fill_between(df['v'], df['ci_lo'],df['ci_up'],color='blue',alpha=0.2)
plt.xticks(np.arange(1, 21))
plt.hlines(y=1,xmin=1,xmax=20,linestyle='dashed',color='black')
plt.xlabel('vingtiles de revenu 55-59 ans')
plt.ylabel('risque relatif (10e vingtile = 1)')
plt.savefig('../figures/gradient.png',dpi=1200)
plt.show()
