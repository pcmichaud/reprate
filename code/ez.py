import numpy as np 
from numba import njit, int64, float64, void
from numba.experimental import jitclass
from numba.types import Tuple

@njit(float64(float64,float64,float64,float64),fastmath=True,cache=True)
def bk_fun(w,b_x,b_k,vareps):
    return b_x/(1-vareps) * ((w+b_k)**(1-vareps) - b_k**(1-vareps))

@njit(float64(float64,float64,float64,float64, float64),fastmath=True, cache=True)
def ez_fun(u,ev,beta,gamma,vareps):
    present = (1-beta) *(u**(1.0-vareps))
    ezv = ev**((1.0-vareps)/(1.0-gamma))
    future = beta * ezv
    ez = (present + future)**(1.0/(1.0-vareps))
    return ez

spec_prefs = [
    ('gamma',float64),
    ('b_x',float64),
    ('b_k',float64),
    ('vareps',float64),
    ('beta',float64)
]

@jitclass(spec_prefs)
class set_prefs(object):
    def __init__(self, gamma = 5.98,b_x = 0.01, b_k = 1.0e-3, vareps = 2.3,beta = 0.97):
        self.gamma = gamma
        self.b_x = b_x
        self.b_k = b_k
        self.vareps = vareps
        self.beta = beta
        return

