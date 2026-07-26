#!/usr/bin/env python3
import argparse
import json
import re
import shutil
import time

from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.support.ui import WebDriverWait


def create_driver(browser):
    if browser == "firefox":
        options = webdriver.FirefoxOptions()
        options.add_argument("-headless")
        return webdriver.Firefox(
            options=options,
            service=FirefoxService(executable_path=shutil.which("geckodriver")),
        )

    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    return webdriver.Chrome(
        options=options,
        service=ChromeService(executable_path=shutil.which("chromedriver")),
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--browser", choices=("firefox", "chrome"), default="firefox")
    parser.add_argument("--mode", choices=("benchmark", "human"), default="benchmark")
    parser.add_argument("--threads", choices=("1", "2", "3", "4"), default="1")
    parser.add_argument("--url", default="http://127.0.0.1:8080/")
    args = parser.parse_args()

    driver = create_driver(args.browser)
    started = time.monotonic()
    try:
        url = args.url if args.mode == "benchmark" else f"{args.url}?mode=human"
        driver.get(url)
        wait = WebDriverWait(driver, 180)
        wait.until(lambda d: d.find_element(By.ID, "status-value").text in ("READY", "ERROR"))
        status = driver.find_element(By.ID, "status-value").text
        if status != "READY":
            raise RuntimeError(driver.find_element(By.ID, "log-output").text)

        if args.mode == "benchmark":
            Select(driver.find_element(By.ID, "thread-count")).select_by_value(args.threads)
        driver.find_element(By.ID, "btn-run").click()
        wait = WebDriverWait(driver, 300)
        wait.until(lambda d: d.find_element(By.ID, "status-value").text in ("DONE", "ERROR"))

        status = driver.find_element(By.ID, "status-value").text
        log = driver.find_element(By.ID, "log-output").text
        result = driver.find_element(By.ID, "result-value").text
        match = re.search(r"([0-9.]+) visits/s", result)
        valid_result = match if args.mode == "benchmark" else result == "HumanSL policy returned"
        if status != "DONE" or not valid_result:
            raise RuntimeError(log)

        output = {
            "browser": args.browser,
            "mode": args.mode,
            "threads": int(args.threads) if args.mode == "benchmark" else None,
            "elapsed_seconds": round(time.monotonic() - started, 2),
        }
        if match:
            output["visits_per_second"] = float(match.group(1))
        print(json.dumps(output))
    finally:
        driver.quit()


if __name__ == "__main__":
    main()
