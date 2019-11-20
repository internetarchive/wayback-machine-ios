//
//  HomeViewController.swift
//  WM
//
//  Created by mac-admin on 8/2/17.
//  Copyright © 2017 Admin. All rights reserved.
//
import UIKit

class HelpViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private(set) lazy var contentViewControllers: [UIViewController] = {
        return [self.getContentViewController(identifier: "FirstContentViewController"),
                self.getContentViewController(identifier: "SecondContentViewController"),
                self.getContentViewController(identifier: "ThirdContentViewController")]
    }()
    private var pageViewController: UIPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createPageViewController()
    }
    
    private func createPageViewController() {
        let pageController = self.storyboard!.instantiateViewController(withIdentifier: "RootViewController") as! UIPageViewController
        
        pageController.dataSource = self
        pageController.delegate = self
        
        if let firstViewController = contentViewControllers.first {
            pageController.setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
        pageViewController = pageController
        addChild(pageViewController!)
        
        self.view.insertSubview(pageController.view, belowSubview: self.controlView)
        pageViewController!.didMove(toParent: self)
    }
    
    private func getContentViewController(identifier : String) -> UIViewController {
        return UIStoryboard(name : "Main", bundle : nil).instantiateViewController(withIdentifier: identifier)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = contentViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        guard contentViewControllers.count != nextIndex else {
            return nil
        }
        guard contentViewControllers.count > nextIndex else {
            return nil
        }
        return contentViewControllers[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = contentViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard contentViewControllers.count > previousIndex else {
            return nil
        }
        return contentViewControllers[previousIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return contentViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstPageControllerView = pageViewController.viewControllers?.first, let firstPageControllerViewIndex = contentViewControllers.firstIndex(of: firstPageControllerView) else {
            return 0;
        }
        
        return firstPageControllerViewIndex
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - PageViewController Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed)
        {
            return
        }
        let currentPageIndex = self.contentViewControllers.firstIndex(of: pageViewController.viewControllers![0])!
        pageControl.currentPage = currentPageIndex
    }
}
