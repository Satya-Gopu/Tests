//
//  ViewController.swift
//  Testability
//


import UIKit

class LoadingViewController: UIViewController {
    private lazy var activityIndicator = UIActivityIndicatorView(style: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // We use a 0.5 second delay to not show an activity indicator
        // in case our data loads very quickly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.activityIndicator.startAnimating()
        }
    }
}


extension UIViewController {
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }
        
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

// Composition - Buing larger blocks using small components, A bottom up approach

class ListViewController: UITableViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadItems()
    }
    
    private func loadItems() {
        let loadingViewController = LoadingViewController()
        add(loadingViewController)
        
        dataLoader.loadItems { [weak self] result in
            loadingViewController.remove()
            self?.handle(result)
        }
    }
}

// Extraction - Extracting logic from the larger block into small components that stay strongly coupled.

class User {
    // User object
}

enum ProfileState {
    case loading
    case presenting(User) // presenting user
    case failed(Error)
}

class ProfileLogicController {
    typealias Handler = (ProfileState) -> Void
    
    func load(then handler: @escaping Handler) {
        // Load the state of the view and then run a completion handler
        let cacheKey = "user"
        
        if let existingUser: User = cache.object(forKey: cacheKey) {
            handler(.presenting(existingUser))
            return
        }
        
        dataLoader.loadData(from: .currentUser) { [cache] result in
            switch result {
            case .success(let user):
                cache.insert(user, forKey: cacheKey)
                handler(.presenting(user))
            case .failure(let error):
                handler(.failed(error))
            }
        }
    }
    
    func changeDisplayName(to name: String, then handler: @escaping Handler) {
        // Change the user's display name and then run a completion handler
    }
    
    func changeProfilePhoto(to photo: UIImage, then handler: @escaping Handler) {
        // Change the user's profile photo and then run a completion handler
    }
    
    func logout() {
        // Log the user out, then re-direct to the login screen
    }
}


class ProfileViewController: UIViewController {
    private let logicController: ProfileLogicController
    
    init(logicController: ProfileLogicController) {
        self.logicController = logicController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(_ state: ProfileState) {
        switch state {
        case .loading:
        // Show a loading spinner, for example using a child view controller
        case .presenting(let user):
        // Bind the user model to the view controller's views
        case .failed(let error):
            // Show an error view, for example using a child view controller
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        render(.loading)
        
        logicController.load { [weak self] state in
            self?.render(state)
        }
    }
}


// Property injection:
class NoteManager {
    func loadNotes(matching query: String,
                   completionHandler: @escaping ([Note]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let database = self.loadDatabase()
            let notes = database.filter { note in
                return note.matches(query: query)
            }
            
            completionHandler(notes)
        }
    }
}

class NoteManager2 {
    func loadNotes(matching query: String,
                   on queue: DispatchQueue = .global(qos: .userInitiated),
                   completionHandler: @escaping ([Note]) -> Void) {
        queue.async {
            let database = self.loadDatabase()
            let notes = database.filter { note in
                return note.matches(query: query)
            }
            
            completionHandler(notes)
        }
    }
}

// Refactoring for testability

class ShoppingCart {
    static let shared = ShoppingCart()
    
    private var products = [Product]()
    private var coupon: Coupon?
    
    func add(_ product: Product) {
        products.append(product)
    }
    
    func apply(_ coupon: Coupon) {
        self.coupon = coupon
    }
    
    func startCheckout() {
        var finalPrice = products.reduce(0) { price, product in
            return price + product.cost
        }
        
        if let coupon = coupon {
            let multiplier = coupon.discountPercentage / 100
            let discount = Double(finalPrice) * multiplier
            finalPrice -= Int(discount)
        }
        
        App.router.openCheckoutPage(forProducts: products,
                                    finalPrice: finalPrice)
    }
}


class PriceCalculator {
    static func calculateFinalPrice(for products: [Product],
                                    applying coupon: Coupon?) -> Int {
        var finalPrice = products.reduce(0) { price, product in
            return price + product.cost
        }
        
        if let coupon = coupon {
            let multiplier = coupon.discountPercentage / 100
            let discount = Double(finalPrice) * multiplier
            finalPrice -= Int(discount)
        }
        
        return finalPrice
    }
}

