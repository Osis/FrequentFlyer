import UIKit

class TeamPipelinesViewController: UIViewController {
    @IBOutlet weak var teamPipelinesTableView: UITableView?
    @IBOutlet weak var gearBarButtonItem: UIBarButtonItem?
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView?

    var teamPipelinesService = TeamPipelinesService()
    var keychainWrapper = KeychainWrapper()

    var target: Target?

    var pipelines: [Pipeline]?

    class var storyboardIdentifier: String { get { return "TeamPipelines" } }
    class var showJobsSegueId: String { get { return "ShowJobs" } }
    class var setConcourseEntryAsRootPageSegueId: String { get { return "SetConcourseEntryAsRootPage" } }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let target = target else { return }
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        title = "Pipelines"
        loadingIndicator?.startAnimating()
        teamPipelinesTableView?.separatorStyle = .none
        teamPipelinesService.getPipelines(forTarget: target) { pipelines, error in
            if error is AuthorizationError {
                self.handleAuthorizationError()
                return
            }

            self.handlePipelinesReceived(pipelines!)
        }

        teamPipelinesTableView?.dataSource = self
        teamPipelinesTableView?.delegate = self
    }

    private func handlePipelinesReceived(_ pipelines: [Pipeline]) {
        self.pipelines = pipelines
        DispatchQueue.main.async {
            self.teamPipelinesTableView?.separatorStyle = .singleLine
            self.teamPipelinesTableView?.reloadData()
            self.loadingIndicator?.stopAnimating()
        }
    }

    private func handleAuthorizationError() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Unauthorized",
                message: "Your credentials have expired. Please authenticate again.",
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: "Log Out",
                    style: .destructive,
                    handler: { _ in
                        self.keychainWrapper.deleteTarget()
                        self.performSegue(withIdentifier: TeamPipelinesViewController.setConcourseEntryAsRootPageSegueId, sender: nil)
                }
                )
            )

            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
                self.teamPipelinesTableView?.separatorStyle = .singleLine
                self.teamPipelinesTableView?.reloadData()
                self.loadingIndicator?.stopAnimating()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TeamPipelinesViewController.showJobsSegueId {
            guard let jobsViewController = segue.destination as? JobsViewController else { return  }
            guard let indexPath = sender as? IndexPath else { return }
            guard let pipeline = pipelines?[indexPath.row] else { return }
            guard let target = target else { return }

            jobsViewController.pipeline = pipeline
            jobsViewController.target = target
        } else if segue.identifier == TeamPipelinesViewController.setConcourseEntryAsRootPageSegueId {
            guard let concourseEntryViewController = segue.destination as? ConcourseEntryViewController else {
                return
            }

            concourseEntryViewController.userTextInputPageOperator = UserTextInputPageOperator()

            let authMethodsService = AuthMethodsService()
            authMethodsService.httpClient = HTTPClient()
            authMethodsService.authMethodsDataDeserializer = AuthMethodDataDeserializer()
            concourseEntryViewController.authMethodsService = authMethodsService

            let unauthenticatedTokenService = UnauthenticatedTokenService()
            unauthenticatedTokenService.httpClient = HTTPClient()
            unauthenticatedTokenService.tokenDataDeserializer = TokenDataDeserializer()
            concourseEntryViewController.unauthenticatedTokenService = unauthenticatedTokenService

            concourseEntryViewController.navigationItem.hidesBackButton = true
        }
    }

    @IBAction func gearTapped() {
        let logOutActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        logOutActionSheet.addAction(
            UIAlertAction(
                title: "Log Out",
                style: .destructive,
                handler: { _ in
                    self.keychainWrapper.deleteTarget()
                    self.performSegue(withIdentifier: TeamPipelinesViewController.setConcourseEntryAsRootPageSegueId, sender: nil)
            }
            )
        )

        logOutActionSheet.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .default,
                handler: nil
            )
        )

        DispatchQueue.main.async {
            self.present(logOutActionSheet, animated: true, completion: nil)
        }
    }
}

extension TeamPipelinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let pipelines = pipelines else { return 0 }
        return pipelines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = teamPipelinesTableView?.dequeueReusableCell(withIdentifier: PipelineTableViewCell.cellReuseIdentifier, for: indexPath) as! PipelineTableViewCell
        cell.nameLabel?.text = pipelines?[indexPath.row].name
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension TeamPipelinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: TeamPipelinesViewController.showJobsSegueId, sender: indexPath)
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
