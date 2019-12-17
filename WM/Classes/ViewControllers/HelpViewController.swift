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
    private var pageViewController: UIPageViewController?
    private var priorPage: Int = 0

    private(set) lazy var contentViewControllers: [UIViewController] = {
        return [self.getContentViewController(identifier: "FirstContentViewController"),
                self.getContentViewController(identifier: "SecondContentViewController"),
                self.getContentViewController(identifier: "ThirdContentViewController")]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "pageViewSegueId") {
            pageViewController = segue.destination as? UIPageViewController
            pageViewController?.dataSource = self
            pageViewController?.delegate = self
            if let firstVC = contentViewControllers.first {
                pageViewController?.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
            }
        }
    }

    private func getContentViewController(identifier : String) -> UIViewController {
        return UIStoryboard(name : "Main", bundle : nil).instantiateViewController(withIdentifier: identifier)
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = contentViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        return (contentViewControllers.count > index + 1) ? contentViewControllers[index + 1] : nil
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

    // keep these two functions commented out to hide the built-in page control. (Apple's dumb design...)
    /*
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return contentViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstPageControllerView = pageViewController.viewControllers?.first, let firstPageControllerViewIndex = contentViewControllers.firstIndex(of: firstPageControllerView) else {
            return 0;
        }
        return firstPageControllerViewIndex
    }
    */

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - PageViewController Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentPageIndex = self.contentViewControllers.firstIndex(of: pageViewController.viewControllers![0]) {
            pageControl.currentPage = currentPageIndex
            priorPage = currentPageIndex
        }
    }

    // MARK: - Actions

    @IBAction func onValueChanged(_ sender: Any) {
        // change the page
        let cvc = contentViewControllers[pageControl.currentPage]
        //self.pageViewController?.setViewControllers([cvc], direction: .forward, animated: true, completion: nil)
        self.pageViewController?.setViewControllers([cvc], direction: ( pageControl.currentPage < priorPage ? .reverse : .forward ), animated: true) { _ in
            self.pageControl.updateCurrentPageDisplay()
            self.priorPage = self.pageControl.currentPage
        }
    }

}
