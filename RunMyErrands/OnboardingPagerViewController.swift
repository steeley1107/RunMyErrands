//
//  OnboardingPagerViewController.swift
//  RunMyErrands
//
//  Created by Jeff Mew on 2016-01-18.
//  Copyright © 2016 Jeff Mew. All rights reserved.
//

import UIKit

extension OnboardingPagerViewController : UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if pageIndex == 0 {
            return nil
        } else {
            pageIndex = pageIndex - 1
            
            if pageIndex == 0 {
                return getStepZero()
            } else {
                return getStepOne()
            }
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

        if pageIndex == 2 {
            return nil
        } else {
            
            pageIndex = pageIndex + 1
            
            if pageIndex == 1 {
                return getStepOne()
            } else {
                return getStepTwo()
            }
        }
    }
        
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageIndex
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}



class OnboardingPagerViewController: UIPageViewController {
    
    var pageIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setViewControllers([getStepZero()], direction: .Forward, animated: false, completion: nil)
        dataSource = self
        view.backgroundColor = .darkGrayColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getStepZero() -> UIViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("StepZero")
    }

    func getStepOne() -> UIViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("StepOne")
    }
    
    func getStepTwo() -> UIViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("StepTwo")
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
