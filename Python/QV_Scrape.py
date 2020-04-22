
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
import time
import pandas as pd
from bs4 import BeautifulSoup 
import re


##config
RunHeadless = 0
options = Options()
options.add_argument("--start-maximized")   # QV uses breakpoints, the relevant disapears on small screens, e.g. when the browser is visible and not maxmined
qv = 'https://www.qv.co.nz'
akl = '/ta/auckland/76'
ext = '/sold?sales_price_range_from=0&sales_price_range_to=2000000&bedrooms_from=0&bedrooms_to=0&sale_period=24&sort_results_by=most_recent' # This is the additonal address used for the php query to get the last 2 years of data for all prices
timeN = 20 #seconds

#open chrome and navigate to the right page
if RunHeadless == 1: options.add_argument("--headless") 
d = webdriver.Chrome(executable_path="chromedriver.exe", options=options)
d.get(qv+akl)
WebDriverWait(d, 20).until(EC.visibility_of_element_located((By.XPATH, "//ul[@class='list-unstyled text-left']")))
d.find_element_by_xpath("//div[@class='modal-footer']//button[@class='btn btn-success']").click() #click the cookie button
page = BeautifulSoup(d.page_source, 'lxml')
links = page.find_all("a", href=re.compile("/suburb/"))  #get all the links to the different suburbs

df = pd.DataFrame (columns = ['Suburb','Median', 'Address', 'Land_Area', 'Price'])  #create a dataframe
for i in links:
    try:
        print('f')
        print(qv+i.get('href'))
        d.get(qv+i.get('href'))
        WebDriverWait(d, 5).until(EC.presence_of_element_located((By.XPATH,'//a[@class="navbar-brand"]')))
        url = d.current_url
        if 'unavailable' not in url:
            url = url[:len(url)-5]
            d.get(url+ext)
            medianPrice = (WebDriverWait(d, 5).until(EC.presence_of_element_located((By.XPATH,'//div[@id="medianHomeValue"]//h2')))).text
            next = True
            loaded = False
            while next:
                print('a')
                clicked = False
                while not loaded:
                    print('b')
                    page = BeautifulSoup(d.page_source, 'lxml')
                    time.sleep(2)
                    loaded = page == BeautifulSoup(d.page_source, 'lxml')
                wrap = page.find("div", class_="recentlySoldWrap")
                properties = wrap.find_all("div", class_="col-xs-12")
                while len(properties) == 0:
                    print('c')
                    time.sleep(1)
                    properties = wrap.find_all("div", class_="col-xs-12")
                for j in properties:
                    property = dict(
                        Suburb = i.text,
                        Median = medianPrice,
                        Address = j.find("a").text,
                        Land_Area = j.find("span", class_="landAreaVal").text,
                        Price = j.find("span", class_="salePrice").text
                    )
                    df = df.append(property,ignore_index=True)
                nextButton = d.find_element_by_id("next")
                next = nextButton.get_attribute("class") != 'disabled'
                if next: 
                    count = 0
                    while not clicked and count<=5:
                        print('d')
                        if count == 5: next = False
                        try:
                            WebDriverWait(nextButton, 2).until(EC.element_to_be_clickable((By.TAG_NAME,'span'))).click()
                            clicked = True
                            print('e')
                        except:
                            count = count + 1
                            time.sleep(1)
    except: pass
with open('SalesQV.csv', 'w', newline='', encoding='utf-8') as f:
    df.to_csv(f, header=True, index=False)

    