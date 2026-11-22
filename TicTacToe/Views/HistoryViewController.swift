//
//  HistoryViewController.swift
//  TicTacToe
//
//  Displays the match history stored in UserDefaults.
//

import UIKit

// UITableViewController là màn hình chuyên hiển thị danh sách dòng (table view).
// Controller cung cấp số dòng và nội dung từng dòng qua các hàm override bên dưới.
// Dữ liệu thật nằm trong UserDefaults; records là mảng dùng để hiển thị lần mở này.
final class HistoryViewController: UITableViewController {

    // MARK: - Dependencies

    private let viewModel: GameViewModel

    // MARK: - Data

    private var records: [MatchRecord] = []

    // MARK: - Init

    // Dependency injection: nơi mở màn hình truyền ViewModel vào, thay vì History
    // tự tạo một game mới. Cùng một tham chiếu class được dùng ở cả hai màn hình.
    // .insetGrouped chọn kiểu danh sách theo nhóm với khoảng đệm hai bên.
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    // UIKit yêu cầu initializer này vì lớp cha hỗ trợ giải mã giao diện.
    // Màn hình chỉ được tạo bằng code. fatalError cố ý dừng chương trình nếu ai
    // vô tình khởi tạo nó từ Storyboard; đây không phải cách xử lý lỗi dữ liệu lịch sử.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Match History"
        navigationController?.navigationBar.prefersLargeTitles = true

        // Style nav bar
        // Appearance gom cấu hình của thanh điều hướng; standard dùng bình thường,
        // scrollEdge dùng khi nội dung chạm mép cuộn. ?. chỉ truy cập nếu có navigationController.
        // [.foregroundColor: UIColor.white] là dictionary thuộc tính định dạng chữ.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1)
        appearance.titleTextAttributes     = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(red: 0.18, green: 0.45, blue: 0.90, alpha: 1)

        // Table appearance
        view.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1)
        tableView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1)
        // Đăng ký lớp cell với tên reuseID để table view biết phải tạo kiểu cell nào.
        // Cell được tái sử dụng khi cuộn, không tạo sẵn một UIView cho mọi bản ghi.
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseID)
        tableView.rowHeight = 70
        tableView.separatorColor = UIColor(white: 0.2, alpha: 1)

        // Clear button
        let clearBtn = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearHistory))
        clearBtn.tintColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1)
        navigationItem.rightBarButtonItem = clearBtn

        // Close button
        let closeBtn = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(dismiss_))
        navigationItem.leftBarButtonItem = closeBtn
    }

    // reloadData yêu cầu table view hỏi lại số dòng và nội dung từ các callback.
    // updateEmptyState chọn thông báo nếu không có bản ghi.
    private func loadData() {
        records = viewModel.loadHistory()
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        if records.isEmpty {
            let label = UILabel()
            label.text = "No matches yet.\nPlay a game to see history here."
            label.textAlignment = .center
            // numberOfLines=0 cho phép xuống dòng không giới hạn; \n là ký tự xuống dòng.
            // backgroundView hiển thị ở nền table khi chưa có các cell lịch sử.
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            label.textColor = UIColor(white: 0.45, alpha: 1)
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    // MARK: - Actions

    // Xóa là thao tác phá dữ liệu nên giao diện hỏi người dùng bằng alert.
    // .cancel đóng mà không xóa; .destructive dùng kiểu hiển thị cho thao tác xóa.
    // [weak self] tránh closure giữ màn hình sống lâu hơn cần thiết.
    // `self?.` bỏ qua các câu lệnh khi màn hình đã được giải phóng.
    @objc private func clearHistory() {
        let alert = UIAlertController(
            title: "Clear History",
            message: "This will delete all match records. Continue?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.viewModel.clearHistory()
            self?.records = []
            self?.tableView.reloadData()
            self?.updateEmptyState()
        })
        present(alert, animated: true)
    }

    // dismiss đóng modal đã present; khác navigationController.popViewController
    // là quay lại trong một ngăn xếp điều hướng. Dấu _ cuối tên chỉ là một phần tên hàm.
    @objc private func dismiss_() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource

    // Table có section (nhóm) và row (dòng). App dùng một section chứa các trận.
    // Thân hàm chỉ có một biểu thức có thể bỏ từ khóa return.
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // IndexPath chứa section và row. row bắt đầu từ 0, rank hiển thị bắt đầu từ 1.
        // dequeue lấy cell cũ để tái sử dụng hoặc tạo mới từ lớp đã register.
        // as! ở đây dựa vào cam kết reuseID đã đăng ký đúng HistoryCell;
        // đăng ký nhầm kiểu sẽ làm ép kiểu bắt buộc thất bại.
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.reuseID,
                                                  for: indexPath) as! HistoryCell
        cell.configure(with: records[indexPath.row], rank: indexPath.row + 1)
        return cell
    }

    // Trả String? vì có thể không cần tiêu đề. Toán tử ba ngôi chọn số ít/số nhiều.
    // Chuỗi có interpolation lồng biểu thức, ví dụ 1 game played / 8 games played.
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        records.isEmpty ? nil : "\(records.count) game\(records.count == 1 ? "" : "s") played"
    }
}

// MARK: - HistoryCell

// Kiểu private ở cấp file này chỉ dùng trong file. HistoryCell kế thừa UITableViewCell.
// static reuseID là tên dùng chung cho mọi instance, không phải mã định danh một trận.
private final class HistoryCell: UITableViewCell {

    static let reuseID = "HistoryCell"

    private let rankLabel:   UILabel = makeLabel(size: 13, weight: .medium,  color: UIColor(white: 0.5, alpha: 1))
    private let resultLabel: UILabel = makeLabel(size: 16, weight: .semibold, color: .white)
    private let movesLabel:  UILabel = makeLabel(size: 13, weight: .regular,  color: UIColor(white: 0.6, alpha: 1))
    private let dateLabel:   UILabel = makeLabel(size: 12, weight: .regular,  color: UIColor(white: 0.45, alpha: 1))
    private let resultBadge: UIView  = {
        let v = UIView()
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Hàm trợ giúp gom cấu hình label lặp lại, nhận size/weight/color rồi trả UILabel.
    // static vì tạo label không cần trạng thái của một HistoryCell đã khởi tạo.
    private static func makeLabel(size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1)
        selectedBackgroundView = {
            let v = UIView()
            v.backgroundColor = UIColor(white: 1, alpha: 0.05)
            return v
        }()

        // Thêm nội dung của cell vào contentView để UIKit bố trí/quản lý cell đúng cách.
        // Các anchor bên dưới đặt vạch màu, số thứ tự, kết quả, số nước, ngày giờ.
        contentView.addSubview(resultBadge)
        contentView.addSubview(rankLabel)
        contentView.addSubview(resultLabel)
        contentView.addSubview(movesLabel)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            resultBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resultBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            resultBadge.widthAnchor.constraint(equalToConstant: 6),
            resultBadge.heightAnchor.constraint(equalToConstant: 40),

            rankLabel.leadingAnchor.constraint(equalTo: resultBadge.trailingAnchor, constant: 12),
            rankLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            resultLabel.leadingAnchor.constraint(equalTo: rankLabel.leadingAnchor),
            resultLabel.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 2),

            movesLabel.leadingAnchor.constraint(equalTo: resultLabel.trailingAnchor, constant: 10),
            movesLabel.centerYAnchor.constraint(equalTo: resultLabel.centerYAnchor),

            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // Cell được tái dùng cho record khác nên configure cần gán lại nội dung và màu.
    // `with` là nhãn khi gọi, `record` là tên tham số trong hàm.
    // DateFormatter đổi Date thành chuỗi theo định dạng/thiết lập vùng của thiết bị.
    // Màu badge báo người thắng; rank ở đây là thứ tự lịch sử, không phải bảng xếp hạng.
    func configure(with record: MatchRecord, rank: Int) {
        rankLabel.text  = "#\(rank)"
        resultLabel.text = record.result.rawValue
        movesLabel.text  = "· \(record.totalMoves) moves"

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: record.date)

        switch record.result {
        case .crossWin:  resultBadge.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1)
        case .noughtWin: resultBadge.backgroundColor = UIColor(white: 0.8, alpha: 1)
        case .draw:      resultBadge.backgroundColor = UIColor(red: 0.18, green: 0.45, blue: 0.90, alpha: 1)
        }
    }
}
