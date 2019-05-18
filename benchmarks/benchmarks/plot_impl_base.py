'''
Genera plot de la implementacion "base" en assembly vs la implementacion
`C -O0` y la implementacion `C -O3` para cada filtro.
'''

import pandas as pd
import matplotlib.pyplot as plt

from . import data as rd
from . import utils_plot as up


INPUT_FILES = ['data/resultadosO0-asmNotAligned.csv',
               'data/resultadosO3-asmNotAligned.csv']


def read():
    '''
    Lee los datos para la implementacion base, `C -O0` y `C -O3`.
    '''
    return pd.concat([rd.read_asm_base(), rd.read_o0(), rd.read_o3()],
                     ignore_index=True)


def list_input_files(data):
    '''
    Devuelve lista de archivos de entrada.
    '''
    return set(data['filename'].unique())


def plot(data):
    '''
    '''

    fig, ax = plt.subplots()

    for impl in data['impl'].unique():
        data_this_implementation = data.narrow_by_impl(impl)
        X = data_this_implementation['n_px']
        Y = data_this_implementation['n_ciclos/n_iters']
        ax.plot(X, Y, label=impl, marker='s')

    ax.legend()

    # ax.set_title(f'Ciclos por iteracion para implementacion base de {filter_name}')

    ax.set_xlabel('Cant. pixels (log)')
    ax.set_xscale('log')
    up.set_xlabels(data, ax)

    ax.set_ylabel('Cant. de ciclos promedio (log)')
    ax.set_yscale('log')

    return fig, ax


def __main():

    print('Graficando comparaciones implementacion base vs C')

    data = read()

    for filter_name in data['filtro'].unique():
        print(f'Graficando para {filter_name}')

        # Plot data for this filter
        data_this_filter = data[ data['filtro'] == filter_name ]
        fig, ax = plot(data_this_filter)

        fig.savefig(f'plot_base_{filter_name}.png')


if __name__ == '__main__':
    __main()
