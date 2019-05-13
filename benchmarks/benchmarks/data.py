'''
Funciones para leer y preprocesar los resultados de las mediciones.
'''

import pandas as pd
import re

COLS = ['filtro',
        'impl',
        'filename',
        'bits_dst',
        'n_iters',
        'n_ciclos',
        'n_iters_por_ciclo',
        'opti']


### --------------------------------------------------------------------------
### Aux functions
### --------------------------------------------------------------------------


__SIZE_RE = r'(\d+)x(\d+)'


def __parse_impl(raw_impl):
    '''
    Parsea el valor de entrada de `impl` y devuelve el nombre del lenguaje.

        0 => 'c', 1 => 'asm'
    '''
    langs = ['c', 'asm']
    return langs[ int(raw_impl) ]


def __get_n_pixels(filename):
    '''
    Devuelve la cantidad de pixeles en el experimento dado el filename.
    '''
    match = re.search(SIZE_RE, filename)
    w, h = match.groups()
    return int(w) * int(h)


def __parse_size_label(filename):
    '''
    Devuelve la etiqueta con el tamano de imagen en forma WxH.

    Va a servir para etiquetar los graficos.
    '''
    match = re.search(SIZE_RE, filename)
    return match.group()


def __relabel_impl_con_opti(d):
    '''
    Reescribe la columna `impl` de las mediciones de `c` de modo que figure el
    nivel de optimizacion de compilador.

    Input:
    d -- Dict con un row de la tabla data.

    ejemplo
    -------
    impl, opti, resultado
    asm,  O3,   asm
    c,    01,   c-O3
    '''
    lang = d['impl']
    opti = d['opti']
    return 'asm' if lang == 'asm' else f'{lang}-{opti}'


### --------------------------------------------------------------------------
### Public
### --------------------------------------------------------------------------


def read(filepath):
    '''
    Lee un archivo de mediciones en formato CSV.
    '''

    data = pd.read_csv(filepath, delimiter=';',
                       index_col=False, header=None, names=COLS)

    data['impl'] = data['impl'].apply(__parse_impl)
    data['impl'] = data.apply(__relabel_impl_con_opti, axis=1)
    data['n_px'] = data['filename'].apply(__get_n_pixels)
    data['size'] = data['filename'].apply(__parse_size_label)

    return data
