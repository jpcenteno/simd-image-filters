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
        'n_ciclos/n_iters',
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
    match = re.search(__SIZE_RE, filename)
    w, h = match.groups()
    return int(w) * int(h)


def __parse_size_label(filename):
    '''
    Devuelve la etiqueta con el tamano de imagen en forma WxH.

    Va a servir para etiquetar los graficos.
    '''
    match = re.search(__SIZE_RE, filename)
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
### Monkeypatchs de dataframe
### --------------------------------------------------------------------------

# Quiero extender la clase `pd.DataFrame` para tener metodos mas especificos.
# Herencia no va porque muchos de los metodos son inmutables y devuelven un
# `pd.Dataframe` que debemos volver a wrappear en la clase hija.
#
# La solucion que se me ocurre es monkeypatchear todo. No es una forma elegante
# de hacer esto, pero se puede porque tenemos un solo "tipo" de dataframe. Si
# tuvieramos dos dataframes con distintos datos, ya la estariamos embarrando
# pegandole metodos especificos a una clase que no cumple un rol especifico.


def __filter_set(self):
    'Devuelve conjunto de filtros en el dataset'
    return set(self['filtro'].unique())


def __impl_set(self):
    'Devuelve conjunto de implementaciones en el dataset'
    return set(self['impl'].unique())


def __narrow(self, column, val, drop=True):
    '''Devuelve solo las filas que coinciden con el dato.
    '''
    if column in self.columns:
        self = self[ self[column] == val ]
        if drop:
            self = self.drop(column, axis=1)
    return self


def __narrow_by_filter(self, filter_name, drop=True):
    '''Elige solo las filas con un filtro especifico. '''
    return __narrow(self, 'filtro', filter_name, drop)


def __narrow_by_impl(self, impl_name, drop=True):
    '''Elige solo las filas con una impl especifica. '''
    return __narrow(self, 'impl', impl_name, drop)


# Monkeypatcheo
setattr(pd.DataFrame, 'filter_set', __filter_set)
setattr(pd.DataFrame, 'impl_set', __impl_set)
setattr(pd.DataFrame, 'narrow_by_filter', __narrow_by_filter)
setattr(pd.DataFrame, 'narrow_by_impl', __narrow_by_impl)


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

    data.drop(['bits_dst', 'opti', 'n_iters', 'n_ciclos', 'filename'],
              axis=1, inplace=True)

    data.sort_values('n_px', axis=0, inplace=True)

    return data


def read_asm_base():
    '''
    Lee las mediciones para las implementaciones "base" en Assembly.
    '''
    # En este CSV estan los resultados de las mediciones base y C sin
    # optimizaciones. nos importa solamente la implemtenacion en assembler.
    data = read('data/resultadosO0-asmNotAligned.csv')
    data = data[ data['impl'] == 'asm' ]
    return data


def read_o3():
    '''
    Lee mediciones para la implementacion C de la catedra con `-O3`.
    '''
    data = read('data/resultadosO3-asmNotAligned.csv')
    data = data[ data['impl'] != 'asm' ]
    return data


def read_o0():
    '''
    Lee mediciones para la implementacion C de la catedra con `-O0`.
    '''
    data = read('data/resultadosO0-asmNotAligned.csv')
    data = data[ data['impl'] != 'asm' ]
    return data
