import SwiftUI

/// Tela inicial: logotipo, status do sistema/IA, grade de módulos, histórico
/// recente e terminal integrado.
struct DashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel = DashboardViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: MKTheme.Metric.spacing),
        GridItem(.flexible(), spacing: MKTheme.Metric.spacing)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MKTheme.Metric.spacingLarge) {
                statusHeader
                modulesSection
                historySection
                terminalSection
            }
            .padding(MKTheme.Metric.spacing)
            .padding(.bottom, 40)
        }
        .background(MKBackground())
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { logo }
            ToolbarItem(placement: .topBarTrailing) {
                Button { env.router.openSettings() } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(MKTheme.Color.textSecondary)
                }
            }
        }
    }

    // MARK: Logo

    private var logo: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MKTheme.accentGradient)
                    .frame(width: 30, height: 30)
                Text("MK").font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("MK FLIP").font(MKFont.title(16))
                    .foregroundStyle(MKTheme.Color.textPrimary)
                Text("AI CYBER INTELLIGENCE").font(.system(size: 8, weight: .semibold))
                    .tracking(1.5).foregroundStyle(MKTheme.Color.neon)
            }
        }
    }

    // MARK: Status

    private var statusHeader: some View {
        let status = env.status
        return MKCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    metric(title: "SISTEMA", value: "ONLINE", tint: MKTheme.Color.neon)
                    Divider().frame(height: 34).overlay(MKTheme.Color.hairline)
                    metric(title: "IA", value: status.aiStatus.label.replacingOccurrences(of: "IA ", with: ""),
                           tint: viewModel.statusTint(status.aiStatus))
                    Divider().frame(height: 34).overlay(MKTheme.Color.hairline)
                    metric(title: "MÓDULOS", value: "\(status.onlineModules)/\(status.totalModules)",
                           tint: MKTheme.Color.textPrimary)
                }
                HStack(spacing: 10) {
                    MKButton(title: "Falar com a MK AI", systemImage: "brain.head.profile", kind: .ghost) {
                        env.router.open(.mkAI)
                    }
                    MKButton(title: "Terminal", systemImage: "terminal", kind: .secondary) {
                        env.router.open(.terminal)
                    }
                }
            }
        }
    }

    private func metric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(MKFont.caption()).tracking(1).foregroundStyle(MKTheme.Color.textTertiary)
            Text(value).font(MKFont.mono(14, weight: .semibold)).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Módulos

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MKSectionHeader(title: "Módulos")
            LazyVGrid(columns: columns, spacing: MKTheme.Metric.spacing) {
                ForEach(viewModel.modules) { module in
                    ToolCardView(module: module) { env.router.open(module.id) }
                }
            }
        }
    }

    // MARK: Histórico

    private var historySection: some View {
        let recent = viewModel.recentActivity(from: env.activityLog)
        return VStack(alignment: .leading, spacing: 12) {
            MKSectionHeader(title: "Histórico de atividades")
            MKCard {
                if recent.isEmpty {
                    Text("Nenhuma atividade ainda.").font(MKFont.body())
                        .foregroundStyle(MKTheme.Color.textTertiary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recent) { TerminalLineView(event: $0) }
                    }
                }
            }
        }
    }

    // MARK: Terminal

    private var terminalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MKSectionHeader(title: "Terminal", actionTitle: "Abrir") { env.router.open(.terminal) }
            TerminalPanel(events: env.activityLog.events, maxHeight: 200)
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
