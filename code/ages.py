import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


df = pd.read_excel('../data/distribution.xls',sheet_name='tous')
df.set_index('p',inplace=True)
print(df)

gamma = 0.132
ps = np.arange(1,1001)
ages = np.arange(60,110)
n_p = 1000

def sx(a,alpha,gamma):
    t = a - 60
    return np.exp(-alpha/gamma*(np.exp(gamma*t)-1.0))

def ex(alpha,gamma):
    return np.sum([sx(a,alpha,gamma) for a in ages])


claim_ages = [60,61,62,63,64,65,66]
exs = np.zeros((n_p,len(claim_ages)))


for i,c in enumerate(claim_ages):
    alphas = df[c].values
    for p in range(n_p):
        exs[p,i] = ex(alphas[p],gamma)


stats = np.quantile(exs,q=[0.25,0.5,0.75],axis=0)


labels = ['60','61','62','63','64','65','66-70']

colors = ['blue','red','green','orange','violet','black','yellow']
plt.figure()
plt.plot(claim_ages,stats[1,:],marker='o',color='blue',label='mediane')
plt.fill_between(claim_ages,stats[0,:],stats[2,:],alpha=0.2,color='orange')
for i in range(len(claim_ages)):
    plt.annotate(str(np.round(stats[1,i],1)),(claim_ages[i],stats[1,i]),verticalalignment='bottom')
plt.xlabel('age déclenchement')
plt.ylabel('espérance de vie restante')
plt.savefig('../figures/ages.png',dpi=1200)
plt.show()




exit()

def V(c,tau,alpha,gamma,qx):
    a_c = 1 + tau*(c-65)
    t = c - 60
    return a_c*np.sum([sx(a,alpha,gamma)*np.exp(-r*(a-60)) for a in range(c,110)])

r = 0.03
tau = 0.072

vs = np.zeros(n_p)

for i in range(n_p):
    vs[i] = V(65,tau,alphas[i],ux) - V(60,tau,alphas[i],ux)















