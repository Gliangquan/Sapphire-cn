//
//  MonitoringCore.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-08-30

#if !SAPPHIRE_FULL_BUILD
import Foundation
import SwiftUI

enum MonitorType: String, Codable, CaseIterable {
    case screen, audio, location, calendar, contacts

    var displayName: String { rawValue.capitalized }
    var icon: String { "circle.dashed" }
}

struct DataSummary {
    var totalDataPoints: Int = 0
    var countsByMonitorType: [String: Int] = [:]
    var oldestEntry: Date?
    var newestEntry: Date?
    var databaseSizeMB: Double = 0
}

final class MemorySystemManager {
    static let shared = MemorySystemManager()
    private init() {}

    func getDataSummary() throws -> DataSummary { DataSummary() }
}

struct IntelligenceSettingsView: View {
    @ObservedObject private var locManager = LocalizationManager.shared
    @State private var geminiKey: String = APIKeyManager.shared.geminiAPIKey
    @State private var openAIKey: String = APIKeyManager.shared.openAIAPIKey
    @State private var anthropicKey: String = APIKeyManager.shared.anthropicAPIKey
    @State private var openRouterKey: String = APIKeyManager.shared.openRouterAPIKey

    @State private var showGeminiKey = false
    @State private var showOpenAIKey = false
    @State private var showAnthropicKey = false
    @State private var showOpenRouterKey = false

    @AppStorage("sapphire.gemini.voice") private var geminiVoice: String = "Aoede"
    @AppStorage("sapphire.gemini.model") private var geminiModel: String = "models/gemini-2.5-flash-native-audio-preview-12-2025"
    @AppStorage("sapphire.gemini.systemPrompt") private var systemPrompt: String = ""

    private let availableVoices = ["Aoede", "Puck", "Charon", "Fenrir", "Kore"]
    private let availableModels = [
        ("models/gemini-2.5-flash-native-audio-preview-12-2025", "Gemini 2.5 Flash Native Audio"),
        ("models/gemini-2.0-flash-exp", "Gemini 2.0 Flash Live")
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text(loc("Intelligence"))
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                // MARK: - 1. Google Gemini Live Configuration
                SettingsCard(
                    title: "Google Gemini API",
                    description: "Configure your Google Gemini API key to enable live voice and screen-sharing AI inside the notch."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(loc("Gemini API Key"))
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(geminiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.orange : Color.green)
                                    .frame(width: 8, height: 8)
                                Text(geminiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? loc("Not Configured") : loc("Configured"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 8) {
                            Group {
                                if showGeminiKey {
                                    TextField("AIzaSy...", text: $geminiKey)
                                } else {
                                    SecureField("AIzaSy...", text: $geminiKey)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: geminiKey) { _, newValue in
                                APIKeyManager.shared.geminiAPIKey = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            }

                            Button {
                                showGeminiKey.toggle()
                            } label: {
                                Image(systemName: showGeminiKey ? "eye.slash" : "eye")
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.bordered)

                            if !geminiKey.isEmpty {
                                Button(loc("Clear")) {
                                    geminiKey = ""
                                    APIKeyManager.shared.geminiAPIKey = ""
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        HStack {
                            Text(loc("Keys are stored securely in your macOS Keychain."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let url = URL(string: "https://aistudio.google.com/app/apikey") {
                                Link(loc("Get Free Gemini API Key →"), destination: url)
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    HStack {
                        SettingsRowLabel(
                            title: "Gemini Live Model",
                            description: "Select the multimodal model used for real-time voice and screen interaction."
                        )
                        Spacer()
                        Picker("", selection: $geminiModel) {
                            ForEach(availableModels, id: \.0) { modelId, label in
                                Text(label).tag(modelId)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 240)
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    HStack {
                        SettingsRowLabel(
                            title: "Assistant Voice",
                            description: "Choose the voice persona for Gemini Live responses."
                        )
                        Spacer()
                        Picker("", selection: $geminiVoice) {
                            ForEach(availableVoices, id: \.self) { voice in
                                Text(voice).tag(voice)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                    .padding()
                }

                // MARK: - 2. Other AI Providers
                SettingsCard(
                    title: "Additional AI Providers",
                    description: "Configure optional API keys for OpenAI, Anthropic Claude, and OpenRouter."
                ) {
                    apiKeyRow(
                        title: "OpenAI API Key",
                        placeholder: "sk-...",
                        text: $openAIKey,
                        isVisible: $showOpenAIKey,
                        onSave: { APIKeyManager.shared.openAIAPIKey = $0 }
                    )
                    Divider().padding(.leading, 20)

                    apiKeyRow(
                        title: "Anthropic Claude API Key",
                        placeholder: "sk-ant-...",
                        text: $anthropicKey,
                        isVisible: $showAnthropicKey,
                        onSave: { APIKeyManager.shared.anthropicAPIKey = $0 }
                    )
                    Divider().padding(.leading, 20)

                    apiKeyRow(
                        title: "OpenRouter API Key",
                        placeholder: "sk-or-...",
                        text: $openRouterKey,
                        isVisible: $showOpenRouterKey,
                        onSave: { APIKeyManager.shared.openRouterAPIKey = $0 }
                    )
                }

                // MARK: - 3. Custom System Prompt
                SettingsCard(
                    title: "System Instruction (Prompt)",
                    description: "Customize how the AI assistant behaves and responds when analyzing your screen."
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextEditor(text: $systemPrompt)
                            .font(.system(size: 13))
                            .frame(minHeight: 90)
                            .padding(6)
                            .background(Color.black.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        HStack {
                            Text(loc("Leave empty to use Sapphire's default concise voice assistant prompt."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !systemPrompt.isEmpty {
                                Button(loc("Reset to Default")) {
                                    systemPrompt = ""
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func apiKeyRow(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        onSave: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(loc(title))
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.4) : Color.green)
                        .frame(width: 8, height: 8)
                    Text(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? loc("Not Configured") : loc("Configured"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Group {
                    if isVisible.wrappedValue {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, newValue in
                    onSave(newValue.trimmingCharacters(in: .whitespacesAndNewlines))
                }

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)

                if !text.wrappedValue.isEmpty {
                    Button(loc("Clear")) {
                        text.wrappedValue = ""
                        onSave("")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}
#endif