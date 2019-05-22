//
//  JYViewPager.swift
//  JYViewPager
//
//  Created by 游鴻斌 on 2018/11/30.
//  Copyright © 2018 JerryYou. All rights reserved.
//

import UIKit

protocol JYPageViewDataSource: class {
    func numberOfViews(in pageView: JYPageView) -> Int
    func pageView(_ pageView: JYPageView, viewForPageIndex index: Int) -> UIView
}

protocol JYPageViewDelegate: class {
    func pageView(_ pageView: JYPageView, didSelectPageAt index: Int)
    func pageView(_ pageView: JYPageView, viewDidSwitchPageAt index: Int)
}

extension JYPageViewDelegate {
    func pageView(_ pageView: JYPageView, didSelectPageAt index: Int) {
    }
    
    func pageView(_ pageView: JYPageView, viewDidSwitchPageAt index: Int) {
    }
}

protocol AutoSwitchable {
    func startAutoSwitch(withTimeInterval timeInterval: TimeInterval)
    func stopAutoSwitch()
}

class JYPageView: UIView {
    private var timer: Timer?
    
    private lazy var collectionView: UICollectionView = {
    let layout =  UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        return collectionView
    }()

    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl(frame: CGRect.zero)
        pageControl.hidesForSinglePage = true
        pageControl.defersCurrentPageDisplay = true
        return pageControl
    }()
 
    weak var dataSource: JYPageViewDataSource?
    weak var delegate: JYPageViewDelegate?

    var numberOfViews: Int {
        return dataSource?.numberOfViews(in: self) ?? 0
    }
 
    var pageIndex = 0 {
        didSet {
            guard pageIndex != oldValue else { return }
            pageControl.currentPage = pageIndex
            delegate?.pageView(self, viewDidSwitchPageAt: pageIndex)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let dataSource = dataSource else {
            return
        }
        pageControl.numberOfPages = dataSource.numberOfViews(in: self)
        reloadData()
    }

    func reloadData() {
        collectionView.reloadData()
    }


    func changePage(withPageIndex pageIndex: Int, animated: Bool) {
        if pageIndex - 1 > numberOfViews {
            return
        }
        let indexPath = IndexPath(item: pageIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: [.centeredHorizontally], animated: animated)
    }

    private func setupView() {
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        pageControl.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        pageControl.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension JYPageView: UICollectionViewDataSource & UICollectionViewDelegateFlowLayout {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfViews(in: self) ?? 0
    }
  
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach({$0.removeFromSuperview()})
        if let view = dataSource?.pageView(self, viewForPageIndex: indexPath.row) {
            view.frame = cell.bounds
            cell.contentView.addSubview(view)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.pageView(self, didSelectPageAt: indexPath.row)
    }
}

extension JYPageView: AutoSwitchable {

    func startAutoSwitch(withTimeInterval timeInterval: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { _ in
            var nextPageIndex = self.pageIndex + 1
            if nextPageIndex >= self.numberOfViews {
                nextPageIndex = 0
            }
            self.changePage(withPageIndex: nextPageIndex, animated: nextPageIndex != 0)
        })
    }

    func stopAutoSwitch() {
        timer?.invalidate()
    }
}
