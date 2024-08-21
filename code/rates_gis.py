import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from scipy.optimize import root

df = pd.read_excel('../data/alphas_by_decile.xls',sheet_name='data')
df.set_index('decile',inplace=True)
alphas = df.values.reshape(10)
print(alphas)
gamma = 0.132

df = pd.read_excel('../data/RR_original.xls',sheet_name='GIS_rate')

thetas = (df.loc[(df.AC==60) & (df.age==66),'stat'].values.reshape(10) + 
    df.loc[(df.AC==60) & (df.age==70),'stat'].values.reshape(10))/2
print(thetas)
thetas = -np.log(thetas)

ps = np.arange(1,11)
ages = np.arange(60,110)
n_p = 10

def sx(a,alpha,gamma):
    t = a - 60
    return np.exp(-alpha/gamma*(np.exp(gamma*t)-1.0))

def ex(alpha,gamma):
    return np.sum([sx(a,alpha,gamma) for a in ages])


def V(c,tau,alpha,gamma,r , claw = 0.0):
    a_c = 1 + tau*(c-65)
    t = c - 60
    return a_c*np.sum([sx(a,alpha,gamma)*np.exp(-r*(a-60))*np.exp(-claw*(a>=65)) for a in range(c,110)])

r = 0.03
tau_rrq = 0.072


def slack(r,c,alpha,gamma, claw):
    return V(c,tau_rrq,alpha,gamma,r, claw) - V(60,tau_rrq,alpha,gamma,r, claw)

def solve_rate(c,alpha,gamma, claw):
    result = root(slack,0.03,args=(c,alpha,gamma, claw))
    return result.x

rates = np.zeros(n_p)
rates_claw = np.zeros(n_p)
exs = np.zeros(n_p)

for i in range(n_p):
    rates[i] = solve_rate(65,alphas[i],gamma,0.0)
    rates_claw[i] = solve_rate(65,alphas[i],gamma,thetas[i])
    
    exs[i] = ex(alphas[i],gamma)

plt.figure()
plt.plot(ps,rates,label='sans récupération')
plt.plot(ps,rates_claw,label='avec récupération')
plt.legend()
plt.xlabel('décile revenu 55-59')
plt.ylabel('TRI retard à 65 ans')
plt.savefig('../figures/tri_claw.png',dpi=1200)
plt.show()













