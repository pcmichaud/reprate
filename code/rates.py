import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from scipy.optimize import root

df = pd.read_excel('../data/distribution.xls',sheet_name='tous')
df.set_index('p',inplace=True)
print(df)
alphas = df[60].values

gamma = 0.132
ps = np.arange(1,1001)
ages = np.arange(60,110)
n_p = 1000

def sx(a,alpha,gamma):
    t = a - 60
    return np.exp(-alpha/gamma*(np.exp(gamma*t)-1.0))

def ex(alpha,gamma):
    return np.sum([sx(a,alpha,gamma) for a in ages])


def V(c,tau,alpha,gamma,r):
    a_c = 1 + tau*(c-65)
    t = c - 60
    return a_c*np.sum([sx(a,alpha,gamma)*np.exp(-r*(a-60)) for a in range(c,110)])

r = 0.03
tau_rrq = 0.072


def slack(r,c,alpha,gamma):
    return V(c,tau_rrq,alpha,gamma,r) - V(60,tau_rrq,alpha,gamma,r)

def solve_rate(c,alpha,gamma):
    result = root(slack,0.03,args=(c,alpha,gamma))
    return result.x

rates = np.zeros(n_p)
exs = np.zeros(n_p)

for i in range(n_p):
    rates[i] = solve_rate(65,alphas[i],gamma)
    exs[i] = ex(alphas[i],gamma)

plt.figure()
plt.plot(exs,rates)
plt.xlabel('espérance de vie restante')
plt.ylabel('TRI retard à 65 ans')
plt.savefig('../figures/tri.png',dpi=1200)
plt.show()













