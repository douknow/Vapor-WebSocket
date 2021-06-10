//
//  ViewController.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/9.
//

import UIKit
import Combine


class ViewController: UIViewController {

    let urlStr = "ws://127.0.0.1:8080/chat"

    var task: URLSessionWebSocketTask!

    let textField = UITextField()
    let sendButton = UIButton(type: .system)
    let tableView = UITableView()

    var messages: [Message] = [
        Message(style: .send, content: "Hello Anna~@", user: User.users[0], time: Date()),
        Message(style: .receive, content: "Hi Bob~.", user: User.users[0], time: Date())
    ]

    let queue = DispatchQueue(label: "com.viewcontroller.write.messages")

    let reuseReceiveCellIdentifier = "receive-message-cell"
    let reuseSendCellIdentifier = "send-message-cell"

    @Published private var currentUser: User? = nil

    @Published private var destUser: User? = nil

    var subscriptions = Set<AnyCancellable>()


    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupSubscriptions()
    }

    func setupViews() {
        let settingMenu = UIMenu(title: "", image: nil, identifier: nil, options: [.displayInline], children: [
            UIAction(title: "Reconnect", image: UIImage(systemName: "network"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [self] _ in
                reconnect()
            }),

            UIAction(title: "Change User", image: UIImage(systemName: "person.2.fill"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [self] _ in
                changeDestUser()
            })
        ])

        let settingBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "gear"), primaryAction: nil, menu: settingMenu)
        navigationItem.rightBarButtonItem = settingBarButtonItem

        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(SendMessageCell.self, forCellReuseIdentifier: reuseSendCellIdentifier)
        tableView.register(ReceiveMessageCell.self, forCellReuseIdentifier: reuseReceiveCellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        view.addSubview(tableView) {
            $0.top.leading.trailing.equalToSuperview()
        }

        textField.borderStyle = .roundedRect
        textField.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)

        sendButton.setTitle("Send", for: .normal)
        sendButton.isEnabled = false
        sendButton.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        sendButton.addAction(UIAction { [unowned self] _ in
            sendMessage(textField.text!)
        }, for: .touchUpInside)

        let scv = UIStackView(views: [textField, sendButton], axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
        view.addSubview(scv) { [self] in
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
            $0.top.equalTo(tableView.snp.bottom)
        }
    }

    func setupSubscriptions() {
        $currentUser
            .combineLatest($destUser)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] currentUser, destUser in
                let isEnabled = (currentUser != nil) && (destUser != nil)
                textField.isEnabled = isEnabled
                sendButton.isEnabled = isEnabled

                let prompt = currentUser == nil ? "未连接" : "\(currentUser!.username), 已连接"
                let userName = destUser?.username

                navigationItem.prompt = prompt
                navigationItem.title = userName
            })
            .store(in: &subscriptions)
    }

    func reconnect() {
        let ac = UIAlertController(title: "Reconnect", message: "请输入用户ID，0 或 1", preferredStyle: .alert)
        ac.addTextField(configurationHandler: nil)
        ac.addAction(UIAlertAction(title: "Connect", style: .default, handler: { [self] _ in
            let id = ac.textFields?.first?.text ?? "-1"
            currentUser = User.findUser(by: Int(id) ?? -1)

            task?.cancel()
            task = connectToChat(id: id)
            receiveMessage()
            sendButton.isEnabled = true
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }

    func changeDestUser(chooseUserCallback: (() -> Void)? = nil) {
        let ac = UIAlertController(title: "Change chat user", message: nil, preferredStyle: .actionSheet)
        User.users
            .filter { $0.id != currentUser?.id }
            .forEach { user in
                let action = UIAlertAction(title: user.username, style: .default) { [unowned self] _ in
                    destUser = user
                    chooseUserCallback?()
                }
                ac.addAction(action)
            }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }

    func sendMessage(_ content: String) {
        guard let user = destUser, let currentUser = currentUser else {
            changeDestUser { [self] in
                sendMessage(content)
            }
            return
        }

        textField.text?.removeAll()
        let msg = MessageData(to: user.id, content: content, time: Date(), user: currentUser)
        task.send(.string(msg.json)) { [self] error in
            if let error = error {
                print("Send msg error: \(error)")
            }

            saveMessage(content, .send, user, msg.time)
        }
    }

    func showConfirm(_ msg: String) {
        let ac = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Confirm", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }

    func saveMessage(_ content: String, _ style: Message.Style, _ user: User, _ time: Date) {
        queue.sync(flags: .barrier) {
            let message = Message(style: style, content: content, user: user, time: time)
            messages.append(message)

            DispatchQueue.main.sync { [self] in
                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func receiveMessage() {
        task.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                print("Receive message occur an error: \(error)")
            case let .success(message):
                switch message {
                case let .string(content):
                    print("Receive MSG: \(content)")

                    let response = Response(json: content)

                    switch response.type {
                    case let .info(msg):
                        print("info: \(msg)")
                    case let .message(messageData):
                        self.saveMessage(messageData.content, .receive, messageData.user, messageData.time)
                    }
                case let .data(data):
                    print("Receive data")
                @unknown default:
                    break
                }
            }

            self.receiveMessage()
        }
    }

    func connectToChat(id: String) -> URLSessionWebSocketTask {
        let task = URLSession.shared.webSocketTask(with: createUrlByUser(id: id))
        task.resume()
        return task
    }

    func createUrlByUser(id: String) -> URL {
        var urlComponents = URLComponents(string: urlStr)!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: id)]
        return urlComponents.url!
    }

}


extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        switch message.style {
        case .receive:
            return (tableView.dequeueReusableCell(withIdentifier: reuseReceiveCellIdentifier, for: indexPath) as! ReceiveMessageCell)
                .config(message)
        case .send:
            return (tableView.dequeueReusableCell(withIdentifier: reuseSendCellIdentifier, for: indexPath) as! SendMessageCell)
                .config(message)
        }
    }

}



