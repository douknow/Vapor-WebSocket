//
//  ViewController.swift
//  WebSocketClient
//
//  Created by Xianzhao Han on 2021/6/9.
//

import UIKit
import Combine
import MobileCoreServices


class ViewController: UIViewController {

    enum NetworkError: Error {
        case noTextResponse, networkError(Error)
    }


    enum State {
        case ready, connecting, connected
    }


    // MARK: - Views

    let textField = UITextField()
    let imageButton = UIButton(type: .system)
    let tableView = UITableView()


    // MARK: - Constants

    let urlStr = "ws://127.0.0.1:8080/chat"

    let queue = DispatchQueue(label: "com.viewcontroller.write.messages")

    let reuseReceiveCellIdentifier = "receive-message-cell"
    let reuseSendCellIdentifier = "send-message-cell"


    // MARK: - Properties

    var task: URLSessionWebSocketTask?

    var messages: [Message] = [
        Message(style: .send, content: .text("Hello Anna~@"), user: User.users[0], time: Date()),
        Message(style: .receive, content: .img(URL(string: "http://localhost:8080/8AAD0977-BD23-4D37-8AB2-E204C3300C64.heic")!), user: User.users[0], time: Date())
    ]

    var subscriptions = Set<AnyCancellable>()


    // MARK: - Observable Variable

    @Published private var currentUser: User? = nil

    @Published private var destUser: User? = nil

    @Published private var state: State = .ready


    // MARK: - ViewController Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupSubscriptions()
    }


    // MARK: - Helper Methods

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
        textField.returnKeyType = .send
        textField.delegate = self

        imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
        imageButton.isEnabled = false
        imageButton.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        imageButton.addAction(UIAction { [unowned self] _ in
            showImagePicker()
        }, for: .touchUpInside)

        let scv = UIStackView(views: [textField, imageButton], axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
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
                imageButton.isEnabled = isEnabled
                navigationItem.title = destUser?.username
            })
            .store(in: &subscriptions)

        $state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .map { state in
                switch state {
                case .ready:
                    return "未连接"
                case .connecting:
                    return "连接中"
                case .connected:
                    return "已连接"
                }
            }
            .assign(to: \.navigationItem.prompt, on: self)
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
            imageButton.isEnabled = true
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }

    func disconnect() {
        task?.cancel()
        task = nil
        state = .ready
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

    func sendMessage(_ content: Message.Content) {
        guard let task = task, state == .connecting else { return }

        guard let user = destUser, let currentUser = currentUser else {
            changeDestUser { [self] in
                sendMessage(content)
            }
            return
        }

        textField.text?.removeAll()

        let msg: MessageData
        switch content {
        case let .img(url):
            msg = ImgMessageData(to: user.id, time: Date(), user: currentUser, imgURL: url)
        case let .text(content):
            msg = TextMessageData(to: user.id, time: Date(), user: currentUser, content: content)
        }

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

    func saveMessage(_ content: Message.Content, _ style: Message.Style, _ user: User, _ time: Date) {
        queue.sync(flags: .barrier) {
            let message = Message(style: style, content: content, user: user, time: time)
            messages.append(message)

            DispatchQueue.main.sync { [self] in
                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: .automatic)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }

    func receiveMessage() {
        guard let task = task else { return }

        task.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(message):
                switch message {
                case let .string(content):
                    print("Receive MSG: \(content)")
                    self.handleContent(content)
                    self.receiveMessage()
                default:
                    break
                }
            default:
                self.disconnect()
            }
        }
    }

    func handleContent(_ content: String) {
        let response = Response(json: content)

        switch response.type {
        case let .info(msg):
            print("info: \(msg)")
        case let .text(messageData):
            self.saveMessage(.text(messageData.content), .receive, messageData.user, messageData.time)
        case let .img(messageData):
            self.saveMessage(.img(messageData.imgURL), .receive, messageData.user, messageData.time)
        }
    }

    func connectToChat(id: String) -> URLSessionWebSocketTask {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        let task = session.webSocketTask(with: createUrlByUser(id: id))
        task.resume()
        state = .connecting
        return task
    }

    func createUrlByUser(id: String) -> URL {
        var urlComponents = URLComponents(string: urlStr)!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: id)]
        return urlComponents.url!
    }

    func uploadImage(_ image: UIImage, fileName: String) -> AnyPublisher<String, NetworkError> {
        let url = URL(string: "http://localhost:8080/upload?key=\(fileName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let data = image.jpegData(compressionQuality: 0.7)
        return Future { promise in
            let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                if let error = error {
                    promise(.failure(NetworkError.networkError(error)))
                    return
                }

                guard let data = data, let result = String(data: data, encoding: .utf8) else {
                    promise(.failure(NetworkError.noTextResponse))
                    return
                }

                promise(.success(result))
            }
            task.resume()
        }
        .eraseToAnyPublisher()
    }

    func showImagePicker() {
        let vc = UIImagePickerController()
        vc.allowsEditing = false
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }

}


// MARK: - UIImagePickerController Delegate

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            print("No origin image")
            return }

        uploadImage(image, fileName: "\(UUID().uuidString).heic")
            .receive(on: DispatchQueue.main)
            .sink { complete in
                if case let .failure(error) = complete {
                    print("Upload error: \(error)")
                }
            } receiveValue: { fileName in
                print("Upload complete: ", fileName)
                self.sendMessage(.img(URL(string: "http://localhost:8080/\(fileName)")!))
            }
            .store(in: &subscriptions)

        picker.dismiss(animated: true, completion: nil)
    }

}


// MARK: - UITableView DataSource

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


// MARK: - UITextField Delegate

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage(.text(textField.text!))
        return false
    }

}


// MARK: - URLSessionWebSocket Delegate

extension ViewController: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Websocket handshake successful")
        state = .connected
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Websocket close by code: \(closeCode)")
        state = .ready
    }

}
