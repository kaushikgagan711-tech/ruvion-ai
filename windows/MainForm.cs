using System;
using System.IO;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace Ruvion.Windows;

public sealed class MainForm : Form
{
    private readonly WebView2 webView = new();

    public MainForm()
    {
        Text = "RUVION";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new System.Drawing.Size(980, 700);
        Width = 1440;
        Height = 920;
        BackColor = System.Drawing.Color.FromArgb(10, 12, 16);

        webView.Dock = DockStyle.Fill;
        Controls.Add(webView);
        Load += LoadRuvion;
    }

    private async void LoadRuvion(object? sender, EventArgs e)
    {
        try
        {
            await webView.EnsureCoreWebView2Async();
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
            webView.CoreWebView2.Settings.IsStatusBarEnabled = false;
            webView.CoreWebView2.Settings.AreDevToolsEnabled = false;

            var entry = Path.Combine(AppContext.BaseDirectory, "web", "index.html");
            if (!File.Exists(entry))
            {
                MessageBox.Show("RUVION web assets were not included in this build.", "RUVION", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            webView.CoreWebView2.Navigate(new Uri(entry).AbsoluteUri);
        }
        catch (Exception error)
        {
            MessageBox.Show($"RUVION could not start. Install Microsoft Edge WebView2 Runtime and try again.\n\n{error.Message}", "RUVION", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
