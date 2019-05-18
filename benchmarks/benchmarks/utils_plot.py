'''
Funciones auxiliares para generar los graficos.
'''


def set_xlabels(data, ax):
    '''
    Configura los `xlabels` de un `Axes` de Matplotlib con los tamanos de las
    imagenes en `data`.

    Utilza metodos mutables de ax.
    '''

    data = data.loc[:, ['size', 'n_px']]
    data = data.groupby('size').mean()  # Dict size => n_px
    data = data.reset_index(level=0)  # 2 cols: size (label), n_px
    data = data.sort_values('n_px')

    ax.set_xticks(data['n_px'])
    ax.set_xticklabels(data['size'])

    # Pone en blanco ticks menores, no se usan xq dominio X es discreto.
    ax.set_xticks([], minor=True)
