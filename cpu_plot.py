import pandas as pd, matplotlib.pyplot as plt, os

DATA_DIR = './cpu'

FILES = {
    'context_switches.csv': {
        'title': 'Context Switches',
        'cols': ['voluntary_rate', 'involuntary_rate'],
        'ylabel': 'Switches/sec',
        'window': 10,  
    },
    'core_distribution.csv': {
        'title': 'Per-Core Load',
        'cols': 'all_cpu',
        'ylabel': 'CPU %',
        'window': 10,
        'linewidth': 1.5,
        'alpha': 0.8
    },
    'process_cpu.csv': {
        'title': 'Process CPU',
        'cols': ['user_pct', 'system_pct'],
        'ylabel': 'CPU %',
        'window': 10,
    },
    'scheduler_wait.csv': {
        'title': 'Scheduler Latency',
        'cols': ['run_delay_ms'],
        'ylabel': 'Milliseconds',
        'color': ['red'],
        'window': 10,
    },
    'system_cpu.csv': {
        'title': 'System CPU',
        'cols': ['user_pct', 'system_pct', 'iowait_pct'],
        'ylabel': 'CPU %',
        'window': 10,
    },
    'thread_count.csv': {
        'title': 'Active Threads Count',
        'cols': ['num_threads'],
        'ylabel': 'Count',
        'color': ['purple'],
        'window': 10, 
    }
}

def plot_dashboard():
    _, axes = plt.subplots(nrows=3, ncols=2, figsize=(20, 14), constrained_layout=True)
    axes = axes.flatten()
    for i, (filename, config) in enumerate(FILES.items()):
        path = os.path.join(DATA_DIR, filename)
        df = pd.read_csv(path)
        df['timestamp'] = pd.to_datetime(df['timestamp'], unit='s')
        df.set_index('timestamp', inplace=True)
        if config['cols'] == 'all_cpu':
            cols_to_plot = [c for c in df.columns if c.startswith('cpu')]
        else:
            cols_to_plot = config['cols']

        window = config.get('window', 10)
        plot_data = df[cols_to_plot].rolling(window=window, min_periods=1).mean()

        ax = axes[i]; colors = config.get('color', None)
        lw = config.get('linewidth', 2.0); alpha = config.get('alpha', 1.0)
        plot_data.plot(ax=axes[i], color=colors, linewidth=lw, alpha=alpha)

        axes[i].set_title(config['title'], fontsize=14, fontweight='bold')
        axes[i].set_ylabel(config.get('ylabel', ''), fontsize=12)
        axes[i].set_xlabel('')
        axes[i].grid(True, linestyle=':', alpha=0.6)
        ax.legend(loc='upper right', fontsize='x-small', ncol=2)

    plt.suptitle(f"CPU Analysis", fontsize=20)
    plt.savefig('cpu_plot.png', dpi=150)

if __name__ == "__main__":
    plot_dashboard()
