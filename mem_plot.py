import pandas as pd
import matplotlib.pyplot as plt
import os

DATA_DIR = './mem'
WINDOW_SIZE = 30
LOAD_ENABLED = False

FILES = {
    'file_locks.csv': {
        'title': 'File Lock Contention',
        'cols': ['threads_waiting_lock'],
        'ylabel': 'Threads Waiting',
        'color': ['red'],
        'window': WINDOW_SIZE,
    },
    'io_latency.csv': {
        'title': 'Disk Latency (Delay Acct)',
        'cols': ['io_latency_ms'],
        'ylabel': 'Milliseconds',
        'color': ['orange'],
        'window': WINDOW_SIZE,
    },
    'iops.csv': {
        'title': 'Disk IOPS',
        'cols': ['read_iops', 'write_iops'],
        'ylabel': 'Ops/sec',
        'window': WINDOW_SIZE,
    },
    'memory_faults.csv': {
        'title': 'Memory Page Faults',
        'cols': ['minor_faults', 'major_faults'],
        'ylabel': 'Faults/sec',
        'window': WINDOW_SIZE,
    },
    'page_cache.csv': {
        'title': 'Page Cache Throughput',
        'cols': ['logical_read', 'logical_write', 'phys_read', 'phys_write'],
        'ylabel': 'MB/sec',
        'window': WINDOW_SIZE,
    },
    'rss_vsz.csv': {
        'title': 'Memory Growth (Diff per sec)',
        'cols': ['rss_anon', 'rss_file', 'vsz'],
        'ylabel': 'KB Change/sec',
        'window': WINDOW_SIZE,
    }
}

def plot_dashboard():
    _, axes = plt.subplots(nrows=3, ncols=2, figsize=(20, 14), constrained_layout=True)
    axes = axes.flatten()
    for i, (filename, config) in enumerate(FILES.items()):
        filename = f"{filename[:-4]}_{'load_enabled' if LOAD_ENABLED else 'load_disabled'}.csv"
        path = os.path.join(DATA_DIR, filename)
        df = pd.read_csv(path)
        df['timestamp'] = pd.to_datetime(df['timestamp'], unit='s')
        df.set_index('timestamp', inplace=True)
        cols_to_plot = config['cols']
        window = config.get('window', 1)
        plot_data = df[cols_to_plot].rolling(window=window, min_periods=1).mean()

        colors = config.get('color', None); lw = config.get('linewidth', 2.0); alpha = config.get('alpha', 1.0)

        plot_data.plot(ax=axes[i], color=colors, linewidth=lw, alpha=alpha)

        axes[i].set_title(config['title'], fontsize=14, fontweight='bold')
        axes[i].set_ylabel(config.get('ylabel', ''), fontsize=12)
        axes[i].set_xlabel('')
        axes[i].grid(True, linestyle=':', alpha=0.6)
        axes[i].legend(loc='upper right', fontsize='x-small', ncol=2)

    title = f"Memory & I/O Analysis {f" (Mean smoothed with window={WINDOW_SIZE})" if WINDOW_SIZE > 1 else ''}"
    smoothed_prt = 'smoothed' if WINDOW_SIZE > 1 else 'unsmoothed'
    load_prt = 'load_enabled' if LOAD_ENABLED else 'load_disabled'
    path = f"./images/mem_{smoothed_prt}_{load_prt}.png"
    plt.suptitle(title, fontsize=20)
    plt.savefig(path, dpi=150)

if __name__ == "__main__":
    plot_dashboard()
