/* ====================================================================
   Karabakh University Library Analytics - BigQuery SQL Queries
   Author: İlkin Nadirli
   Description: Core analytical queries used for exploratory data analysis,
                circulation metrics, room booking patterns, and KPI tracking.
   ==================================================================== */

-- ====================================================================
-- SECTION 1: CIRCULATION & READING PATTERNS
-- ====================================================================

-- 1. Top 10 Most Borrowed Books (Overall)
SELECT 
    UPPER(Edebiyyat) AS edebiyyat,
    COUNT(*) AS say
FROM `library-project-508900.cleaneddatas.library`
GROUP BY UPPER(Edebiyyat)
ORDER BY say DESC
LIMIT 10;

-- 2. Top 10 Books Borrowed by Faculty / Teachers
SELECT 
    UPPER(Edebiyyat) AS edebiyyat,
    COUNT(*) AS say 
FROM `library-project-508900.cleaneddatas.library`
WHERE Oxucu_tipi = 'Müəllim'
GROUP BY UPPER(Edebiyyat)
ORDER BY say DESC
LIMIT 10;

-- 3. Top 10 Faculty Members with Highest Borrowing Activity
SELECT 
    Ad, 
    Soyad, 
    Rol_ve_ya_Ixtisas, 
    COUNT(*) AS kitab_sayi 
FROM `library-project-508900.cleaneddatas.library`
WHERE Oxucu_tipi = 'Müəllim'
GROUP BY Ad, Soyad, Rol_ve_ya_Ixtisas
ORDER BY kitab_sayi DESC
LIMIT 10;

-- 4. Top 10 Students with Highest Borrowing Activity
SELECT 
    Ad, 
    Soyad, 
    Rol_ve_ya_Ixtisas, 
    COUNT(*) AS kitab_sayi 
FROM `library-project-508900.cleaneddatas.library`
WHERE Oxucu_tipi = 'Tələbə'
GROUP BY Ad, Soyad, Rol_ve_ya_Ixtisas
ORDER BY kitab_sayi DESC
LIMIT 10;

-- 5. Top 10 Books Borrowed by Students
SELECT 
    UPPER(Edebiyyat) AS edebiyyat,
    COUNT(*) AS say 
FROM `library-project-508900.cleaneddatas.library`
WHERE Oxucu_tipi = 'Tələbə'
GROUP BY UPPER(Edebiyyat)
ORDER BY say DESC
LIMIT 10;

-- 6. Top Books Borrowed by Specific Majors (Breakdown by Department)
SELECT 
    UPPER(Rol_ve_ya_Ixtisas) AS ixtisas,
    UPPER(Edebiyyat) AS edebiyyat,
    COUNT(*) AS kitab_sayi 
FROM `library-project-508900.cleaneddatas.library`
GROUP BY UPPER(Rol_ve_ya_Ixtisas), UPPER(Edebiyyat)
ORDER BY kitab_sayi DESC
LIMIT 25;

-- 7. Total Circulation Volume by Department / Major
SELECT 
    UPPER(Rol_ve_ya_Ixtisas) AS ixtisas,
    COUNT(*) AS kitab_sayi 
FROM `library-project-508900.cleaneddatas.library`
GROUP BY UPPER(Rol_ve_ya_Ixtisas)
ORDER BY kitab_sayi DESC
LIMIT 10;


-- ====================================================================
-- SECTION 2: STUDY ROOM RESERVATIONS
-- ====================================================================

-- 8. Top 10 Users with Highest Study Room Reservations
SELECT 
    UPPER(Ad) AS ad,
    UPPER(Soyad) AS soyad, 
    COUNT(*) AS otaq_sayi 
FROM `library-project-508900.cleaneddatas.library1`
GROUP BY UPPER(Ad), UPPER(Soyad)
ORDER BY otaq_sayi DESC
LIMIT 10;

-- 9. Room Bookings by Department (Joined with User Profiles from Circulation Data)
SELECT 
    UPPER(TRIM(dovriyye.Rol_ve_ya_Ixtisas)) AS ixtisas, 
    COUNT(*) AS otaq_sayi 
FROM `library-project-508900.cleaneddatas.library1` AS otaq
LEFT JOIN (
    SELECT
        UPPER(TRIM(Ad)) AS Ad,
        UPPER(TRIM(Soyad)) AS Soyad,
        ANY_VALUE(UPPER(TRIM(Rol_ve_ya_Ixtisas))) AS Rol_ve_ya_Ixtisas
    FROM `library-project-508900.cleaneddatas.library`
    GROUP BY UPPER(TRIM(Ad)), UPPER(TRIM(Soyad))
) AS dovriyye
ON UPPER(TRIM(otaq.Ad)) = dovriyye.Ad AND UPPER(TRIM(otaq.Soyad)) = dovriyye.Soyad
GROUP BY UPPER(TRIM(dovriyye.Rol_ve_ya_Ixtisas))
ORDER BY otaq_sayi DESC
LIMIT 10;

-- 10. Peak Reservation Hours for Study Rooms
SELECT 
    SPLIT(Baslama, ':')[OFFSET(0)] AS saat, 
    COUNT(*) AS say 
FROM `library-project-508900.cleaneddatas.library1`
GROUP BY saat
ORDER BY say DESC
LIMIT 5;


-- ====================================================================
-- SECTION 3: TIME-SERIES & COMPARATIVE USAGE ANALYSIS
-- ====================================================================

-- 11. Activity Distribution by Day of Week (Circulation vs Room Bookings)
WITH butun_fealiyyetler AS (
    SELECT FORMAT_DATE('%A', Verilme_Tarixi) AS hefte_gunu, 'Dovriyye' AS nov
    FROM `library-project-508900.cleaneddatas.library`
    WHERE Verilme_Tarixi IS NOT NULL

    UNION ALL

    SELECT Hefte_Gunu AS hefte_gunu, 'Otaq' AS nov
    FROM `library-project-508900.cleaneddatas.library1`
    WHERE Hefte_Gunu IS NOT NULL
)
SELECT
    hefte_gunu,
    COUNT(*) AS umumi_fealiyyet,
    COUNTIF(nov = 'Dovriyye') AS kitab_sayi,
    COUNTIF(nov = 'Otaq') AS otaq_sayi
FROM butun_fealiyyetler
GROUP BY hefte_gunu
ORDER BY umumi_fealiyyet DESC;

-- 12. Monthly Trends across Circulation and Room Services
WITH butun_fealiyyetler AS (
    SELECT FORMAT_DATE('%B', Verilme_Tarixi) AS ay, 'Dovriyye' AS nov
    FROM `library-project-508900.cleaneddatas.library`
    WHERE Verilme_Tarixi IS NOT NULL

    UNION ALL

    SELECT FORMAT_DATE('%B', Tarix) AS ay, 'Otaq' AS nov
    FROM `library-project-508900.cleaneddatas.library1`
    WHERE Tarix IS NOT NULL
)
SELECT
    ay,
    COUNT(*) AS umumi_fealiyyet,
    COUNTIF(nov = 'Dovriyye') AS kitab_sayi,
    COUNTIF(nov = 'Otaq') AS otaq_sayi
FROM butun_fealiyyetler
GROUP BY ay
ORDER BY umumi_fealiyyet DESC;

-- 13. Academic Semester Activity Comparison
WITH butun_fealiyyetler AS (
    SELECT Verilme_Tarixi AS tarix, 'Dovriyye' AS nov
    FROM `library-project-508900.cleaneddatas.library`
    WHERE Verilme_Tarixi IS NOT NULL

    UNION ALL

    SELECT Tarix AS tarix, 'Otaq' AS nov
    FROM `library-project-508900.cleaneddatas.library1`
    WHERE Tarix IS NOT NULL
)
SELECT
    CASE
        WHEN tarix BETWEEN '2025-02-01' AND '2025-06-30' THEN '2024/2025 Yaz'
        WHEN tarix BETWEEN '2025-09-01' AND '2026-01-31' THEN '2025/2026 Payız'
        WHEN tarix BETWEEN '2026-02-01' AND '2026-06-30' THEN '2025/2026 Yaz'
        ELSE 'Tətil / Digər'
    END AS semestr,
    COUNT(*) AS umumi_emeliyyat,
    COUNTIF(nov = 'Dovriyye') AS kitab_sayi,
    COUNTIF(nov = 'Otaq') AS otaq_sayi
FROM butun_fealiyyetler
GROUP BY semestr
ORDER BY umumi_emeliyyat DESC;
