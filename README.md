# Reducing Downtime and Improving Production Efficiency at Jones Soda  

## 1. Introduction  

At Jones Soda, every minute of production counts. However, recent data has revealed a major issue—**excessive machine downtime** is disrupting production efficiency, leading to lost batches and reduced output  

### Key Insights 
 **1,388 minutes of total downtime** recorded  
 **1,027 minutes (74%) caused by top recurring issues**  
 **Machine adjustments often lead to machine failures**, making the problem worse  
 **14 batches lost due to downtime**  

**The Goal?** Reduce downtime by **50%**, recover lost batches, and improve overall production efficiency.  

---

## 2. Identifying the Downtime Problem  

To understand the root causes of downtime, we analyzed **four key production datasets**:  

- **line_productivity**: Tracks production start and end times
- **line_downtime**: Logs machine downtime occurrences and causes
- **Products**: Information about each product
- **Downtime_Factors**: The decription of each downtime cause and if caused by an operator

We started by calculating the **getting our baselines** and identifying the **main reasons behind the delays**  

---

## 3. Data and some SQL Queries used  

### **3.1 Dataset Cleaning & Preparation**  

To make the **line_downtime** table **clean for analysis**, we **cleaned and unpivoted** the data:  

```sql
WITH cleaned_data AS (
    SELECT 
        Batch,
        COALESCE("Factor1", 0) AS "1",
        COALESCE("Factor2", 0) AS "2",
        COALESCE("Factor3", 0) AS "3",
        COALESCE("Factor4", 0) AS "4",
        COALESCE("Factor5", 0) AS "5",
        COALESCE("Factor6", 0) AS "6",
        COALESCE("Factor7", 0) AS "7",
        COALESCE("Factor8", 0) AS "8",
        COALESCE("Factor9", 0) AS "9",
        COALESCE("Factor10", 0) AS "10",
        COALESCE("Factor11", 0) AS "11",
        COALESCE("Factor12", 0) AS "12"
    FROM line_downtime
)

SELECT 
    Batch,
    Factor_ID,
    Downtime_Minutes
FROM cleaned_data
UNPIVOT (Downtime_Minutes FOR Factor_ID IN ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12")
) AS unpivoted_data;
```

---

### **3.2 Calculating Total Downtime Per Product**  

```sql
SELECT lp.Product, SUM(ld.Downtime_Mins) AS total_downtime
FROM Line_Productivity lp
JOIN line_downtime1 ld ON lp.Batch = ld.Batch
GROUP BY lp.Product
ORDER BY total_downtime DESC;
```

 **CO-600 had the highest downtime (35.59%)**
 **CO-2L and RB-600 had 100% batch failure rates due to excessive adjustments**

---

### **3.3 Major Downtime Causes Per Product**  

```sql
SELECT lp.Product, df.description, 
       SUM(ld.Downtime_Mins) AS total_downtime,
       RANK() OVER (PARTITION BY lp.Product ORDER BY SUM(ld.Downtime_Mins) DESC) AS downtime_cause
FROM line_downtime1 ld
JOIN Line_Productivity lp ON ld.Batch = lp.Batch
LEFT JOIN Downtime_Factors df ON ld.Factor = df.Factor
GROUP BY lp.Product, df.description;
```

🔹 **Machine adjustments** are leading to frequent breakdowns.  
🔹 **CO-600 is the biggest bottleneck, followed by CO-2L and RB-600**  

---

### **3.4 Batches Affected By Downtime**  

```sql
SELECT lp.product, 
       COUNT(DISTINCT lp.Batch) AS affected_batches 
FROM line_downtime1 ld
LEFT JOIN line_productivity lp ON ld.batch = lp.batch
WHERE Downtime_Mins > 0
GROUP BY lp.Product;
```

---

## 4. Data Analysis & Key Findings  

### **4.1 Downtime Breakdown**  

| **Issue** | **Total Downtime (mins)** | **% of Total Downtime** |
|------------|--------------------|------------------------|
| **Machine Failures** | 611 mins | 44% |
| **Machine Adjustments** | 416 mins | 30% |
| **Batch Change** | 277 mins | 20% |

🚨 **Machine adjustments are often causing machine failures**, creating a **vicious cycle** of inefficiency

---

### **4.2 Most Affected Products**  

| **Product** | **Total Downtime (mins)** | **% of Total Downtime** | **Batch Failure Rate (%)** | **Primary Issue** |
|------------|------------------------|------------------------|--------------------------|-----------------|
| **CO-600** | 494 mins | 35.59% | 93.33% | Machine failure (caused by adjustments) |
| **CO-2L** | 277 mins | 19.96% | 100% | Machine adjustments |
| **RB-600** | 258 mins | 18.58% | 100% | Machine adjustments |
| **LE-600** | 169 mins | 12.17% | 83.33% | Batch change delays |

📌 **CO-600 alone accounts for over 35% of downtime, making it the biggest bottleneck**  

---

### **4.3 Batches Lost & Recovery Potential**  

| **Product** | **Batches Lost** | **Expected Batches Recovered** |
|------------|---------------|-----------------------|
| **CO-600** | 8 | 4 |
| **CO-2L** | 2 | 1 |
| **RB-600** | 4 | 2 |
| **Total** | 14 | 7 |

By implementing our **recommended fixes**, we can **recover 7 batches** and **save 8 hours of production time**.  

---

## 5. Recommendations  

### **5.1 Fixing Downtime Factors**  

✅ **Preventive Maintenance** – Regular servicing to **reduce machine failures**

✅ **Machine Optimization** – Adjusting CO-2L and RB-600 to **prevent unnecessary adjustments**

✅ **Operator Training** – Teaching operators to **optimize settings correctly** to avoid failures

### **5.2 Expected Impact of Fixes**  

| **Fix** | **Products Affected** | **Expected Downtime Reduction (mins)** | **Batches Recovered** |
|--------|-----------------|------------------------|------------------|
| **Preventive Maintenance** | CO-600, DC-600 | 50% fewer failures | 4 batches |
| **Machine Optimization** | CO-2L, RB-600 | 50% fewer adjustments | 3 batches |
| **Batch Change Process Improvement** | LE-600, OR-600 | Faster transitions | Reduced downtime |

 **Total downtime reduction: ~8 hours (~50%)**  
 **Recovered batches: 7 additional batches**  

---

## 6. Conclusion  

Through SQL analysis, we identified that **machine failures and frequent adjustments account for 74% of downtime at Jones Soda**. Implementing **preventive maintenance, machine optimization, and operator training** will significantly reduce downtime, improve efficiency, and increase production output.  

1. **50% downtime reduction (8+ hours saved)**  
2. **7 additional batches recovered**  
3. **Higher efficiency, reduced costs, and improved output**  

💡 **"Efficiency isn’t just about working harder—it’s about working smarter"**  

---

## 7. Thank You  

For any questions or further analysis, feel free to reach out. 
