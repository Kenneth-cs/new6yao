import Foundation
import PDFKit
import Testing
import UIKit
@testable import LifeCoach

struct ShareExportTests {
    @Test func longPosterIsCappedBeforeJPEGEncoding() {
        let size = PosterPhotoEncoder.targetPixelSize(width: 780, height: 30_000)
        #expect(size.width == 416)
        #expect(size.height == 16_000)

        let short = PosterPhotoEncoder.targetPixelSize(width: 1170, height: 2400)
        #expect(short.width == 1170)
        #expect(short.height == 2400)
    }

    @Test func posterUsesBundledAppStoreQR() {
        let image = ShareQRCode.image(scale: 3)
        #expect(image != nil)
        #expect(image?.size.width == ShareQRCode.pointSize)
        #expect(image?.size.height == ShareQRCode.pointSize)
        #expect(image?.scale == 3)
    }

    @Test func posterPhotoDataIsJPEG() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 40))
        let image = renderer.image { context in
            UIColor.purple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 40))
        }
        let data = PosterPhotoEncoder.jpegData(from: image)
        #expect(data?.starts(with: [0xFF, 0xD8]) == true)
    }

    @Test func longTextIsSplitIntoPosterChunks() {
        let text = String(repeating: "甲\n", count: 400)
        let chunks = ShareText.paragraphChunks(text, limit: 600)
        #expect(chunks.count > 1)
        #expect(chunks.allSatisfy { $0.count <= 600 })
    }

    @Test func posterQuestionTruncatesAfterOneHundredCharacters() {
        let question = String(repeating: "问", count: 120)
        let poster = ShareText.posterQuestion(question)
        #expect(poster.count == 101)
        #expect(poster.hasSuffix("…"))
        #expect(ShareText.posterQuestion("短问题") == "短问题")
    }

    @Test func professionalPDFSkipsEmptyChaptersAndKeepsFullQuestion() {
        let question = String(repeating: "事", count: 120)
        let content = makeDivination(
            question: question,
            mode: .professional,
            conclusion: "当前不宜主动推进",
            analysis: "卦象解析正文",
            verdict: "   ",
            questionInterpretation: "",
            guidance: "暂无解读",
            suggestions: []
        )
        let titles = content.pdfChapters.map(\.title)
        #expect(titles == ["卦象信息", "核心结论", "卦象解析"])
        let info = content.pdfChapters[0].blocks.compactMap { block -> String? in
            if case .prose(let text) = block { return text }
            return nil
        }.joined()
        #expect(info.contains(question))
        #expect(!content.pdfChapters.contains { chapter in
            chapter.blocks.contains { block in
                if case .table = block { return true }
                return false
            }
        })
    }

    @Test func masterPDFFollowsDisplayOrderAndSkipsBlankSections() {
        let content = makeDivination(
            question: "要不要换工作",
            mode: .master,
            conclusion: "不会进入专业七章",
            analysis: "也不会进入卦象解析章",
            masterSections: [
                .init(title: "核心结论", body: "结论甲"),
                .init(title: "卦眼", body: "   "),
                .init(title: "最后一句", body: "收束")
            ]
        )
        #expect(content.pdfChapters.map(\.title) == ["核心结论", "最后一句"])
        #expect(content.fullPosterSections.map(\.title) == ["核心结论", "最后一句"])
    }

    @Test func completePosterKeepsEveryAnalysisSectionInFull() {
        let analysis = String(repeating: "解", count: 180)
        let content = makeDivination(
            question: String(repeating: "问", count: 120),
            mode: .professional,
            conclusion: "一句话结论",
            analysis: analysis,
            verdict: "   ",
            questionInterpretation: "问题解读全文",
            guidance: "建议指导全文",
            suggestions: ["下一步问什么"],
            coreConclusion: "核心结论全文，不截断"
        )
        #expect(content.fullPosterSections.map(\.title) == ["核心结论", "卦象解析", "问题解读", "建议指导", "追问建议"])
        #expect(content.fullPosterSections[0].body == "核心结论全文，不截断")
        #expect(content.fullPosterSections[1].body == analysis)
        #expect(content.fullPosterSections[4].body.contains("下一步问什么"))
        #expect(ShareText.cleaned(content.question).count == 120)
    }

    @Test func deductionPDFIncludesCardSummaryAndFullBasis() {
        let content = makeDeduction()
        let titles = content.pdfChapters.map(\.title)
        #expect(titles.contains("推演背景"))
        #expect(titles.contains("综合推荐"))
        #expect(titles.contains("进路推演"))
        #expect(titles.contains("守路推演"))
        #expect(titles.contains("退路推演"))
        #expect(titles.last == "完整依据")

        let basis = content.pdfChapters.first { $0.title == "完整依据" }
        let text = basis?.blocks.compactMap { block -> String? in
            if case .prose(let value) = block { return value }
            return nil
        }.joined() ?? ""
        #expect(text.contains("本卦对此路的启示"))
        #expect(text.contains("动爻分析"))
        #expect(text.contains("变卦归向"))
        #expect(text.contains("世应·用神·六亲"))
        #expect(text.contains("路径转折点"))
        #expect(text.contains("关键应验点"))
        #expect(text.contains("进路本卦原文"))
    }

    @Test func pdfContainsSelectableTextAndSeparateDisclaimerPage() throws {
        let token = "分享导出校验句"
        let content = makeDivination(
            question: "这段关系该如何发展",
            mode: .professional,
            conclusion: "宜守",
            analysis: token + String(repeating: "爻", count: 1800)
        )
        let payload = SharePayload.divination(content)
        let rendered = try PDFReportGenerator.makeData(payload)
        let document = PDFDocument(data: rendered.data)
        let text = document?.string ?? ""
        #expect(rendered.pageCount >= 3)
        #expect(text.contains("人生教练"))
        #expect(text.contains("解卦报告"))
        #expect(text.contains(token))
        #expect(text.contains("免责声明"))
        #expect(!text.contains("核心断语"))
    }
}

private func makeDivination(
    question: String,
    mode: InterpretationMode,
    conclusion: String,
    analysis: String,
    verdict: String = "",
    questionInterpretation: String = "",
    guidance: String = "",
    suggestions: [String] = [],
    masterSections: [DivinationShareContent.Section] = [],
    coreConclusion: String = ""
) -> DivinationShareContent {
    DivinationShareContent(
        question: question,
        hexagramName: "天地否",
        hexagramDescription: "天地否。象征阴阳不交，万事阻滞。",
        hexagramShortSummary: "天地否",
        yaoLines: [.youngYang, .youngYang, .youngYang, .oldYin, .youngYin, .youngYin],
        liuYaoChart: nil,
        time: Date(timeIntervalSince1970: 1_769_000_000),
        location: "上海市",
        interpretationMode: mode,
        resolvedConclusion: conclusion,
        coreConclusionSection: coreConclusion,
        coreVerdictSection: verdict,
        hexagramAnalysis: analysis,
        questionInterpretation: questionInterpretation,
        guidanceAdvice: guidance,
        suggestions: suggestions,
        masterSections: masterSections,
        fallbackInterpretation: ""
    )
}

private func makeDeduction() -> DeductionShareContent {
    let report = DeductionReport(
        reportVersion: "1",
        question: "这段关系该如何发展",
        backgroundUsed: "已经冷静一周",
        globalJudgment: .init(title: "总断", summary: "先看清再行动", divinationBasisSummary: "用神偏弱", informationGaps: []),
        recommendation: .init(
            status: "ready",
            recommendedPathId: "hold",
            headline: "先守住节奏",
            reason: "主动推进的信号还不够",
            applicableConditions: ["双方还在联系"],
            reconsiderWhen: ["对方明确拒绝"]
        ),
        paths: [
            makePath(id: "advance", name: "主动推进", verdict: "现在推进容易受阻", original: "进路本卦原文"),
            makePath(id: "hold", name: "按兵不动", verdict: "守住现有节奏", original: "守路本卦原文"),
            makePath(id: "withdraw", name: "退出投入", verdict: "退出会留下未完成", original: "退路本卦原文")
        ],
        reportFooter: ""
    )
    return DeductionShareContent(report: report, hexagramName: "天地否", displayQuestion: "这段关系该如何发展")
}

private func makePath(id: String, name: String, verdict: String, original: String) -> DeductionReport.DeductionPathResult {
    DeductionReport.DeductionPathResult(
        id: id,
        fixedName: name,
        rank: 1,
        isRecommended: id == "hold",
        pathAssumption: .init(title: "", content: "沿着\(name)走"),
        pathVerdict: .init(title: "", content: verdict),
        developmentTrend: .init(title: "", opening: "起初", development: "随后", turningPoint: "\(name)转折", possibleOutcome: "结果"),
        pathDivinationReasoning: .init(
            title: "",
            originalHexagram: original,
            movingLines: "\(name)动爻",
            changedHexagram: "\(name)变卦",
            relationAndUseGod: "\(name)世应",
            pathSymbolism: "\(name)象征"
        ),
        verificationSignals: .init(title: "", signals: ["\(name)应验"])
    )
}
