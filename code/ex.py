import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


df = pd.read_excel('../data/distribution.xls',sheet_name='tous')
df.set_index('p',inplace=True)
print(df)
gamma = 0.132

lf = pd.read_excel('../data/quotients_scenario-1861-2026.xlsx')
lf = lf.loc[lf['Scénario']=='ref',1955]
qx = lf[60:].values
ux = - np.log(1-qx)
print(ux,len(ux))

alphas = df['tous'].values

print(np.mean(alphas))


alpha_m = np.mean(alphas)


alphas = alphas/alpha_m

ps = np.arange(1,1001)
ages = np.arange(60,110)
n_p = 1000

def sx_isq(a,alpha,ux):
    t = a - 60
    return np.prod(1-alpha*ux[:t+1])

def sx_lad(a,alpha,gamma):
    t = a - 60
    return np.exp(-alpha*alpha_m/gamma*(np.exp(gamma*t)-1.0))

def ex_isq(alpha,ux):
    return np.sum([sx_isq(a,alpha,ux) for a in ages])

def ex_lad(alpha,gamma):
    return np.sum([sx_lad(a,alpha,gamma) for a in ages])



exs_isq = np.zeros(n_p)
exs_lad = np.zeros(n_p)
for i in range(n_p):
    exs_isq[i] = ex_isq(alphas[i],ux)
    exs_lad[i] = ex_lad(alphas[i],gamma)
print(np.mean(exs_lad),np.quantile(exs_lad,q=[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]))
print(np.mean(exs_isq),np.quantile(exs_isq,q=[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]))
qs = 1001 - ps
plt.figure()
plt.plot(exs_lad,qs/1000)
plt.xlabel('espérance de vie restante')
plt.savefig('../figures/ex.png',dpi=1200)
plt.show()




exit()


def v(c,tau,alpha,qx):
    a_c = 1 + tau*(c-65)
    t = c - 60
    return a_c*np.sum([sx(a,alpha,ux)*np.exp(-r*(a-60)) for a in range(c,110)])

r = 0.03
tau = 0.072
vs = np.zeros(n_p)
for i in range(n_p):
    vs[i] = v(65,tau,alphas[i],ux) - v(60,tau,alphas[i],ux)
print(np.mean(vs),np.quantile(vs,q=[0.01,.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.99]))















