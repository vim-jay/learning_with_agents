package learning.java.interviews;

import java.math.BigDecimal;
import java.util.*;

public class Contracts {
    // 1. equals overridden, hashCode not
    static final class NoHash {

        final int id;

        NoHash(int id) { 
            this.id = id; 
        }

        @Override 
        public boolean equals(Object o) { 
            return o instanceof NoHash n && id == n.id; 
        }
    }

    // 2. equals overloaded instead of overridden
    static final class Overloaded {
        final int id;

        Overloaded(int id) { 
            this.id = id; 
        }

        public boolean equals(Overloaded o) { 
            return o != null && id == o.id; 
        }

        @Override 
        public int hashCode() { 
            return id; 
        }
    }

    // 3. hashCode depends on a field that changes
    static final class Key {

        int id;

        Key(int id) { 
            this.id = id; 
        }

        @Override 
        public boolean equals(Object o) { 
            return o instanceof Key k && id == k.id; 
        }

        @Override 
        public int hashCode() { 
            return id; 
        }
    }

    public static void main(String[] args) {

        var noHash1 = new NoHash(1);
        var noHash2 = new NoHash(1);

        Set<NoHash> set1 = new HashSet<>(List.of(noHash1, noHash2));

        System.out.println("1. size=" + set1.size() + " contains(new NoHash(1))=" + set1.contains(new NoHash(1)));

        Overloaded x = new Overloaded(1), y = new Overloaded(1);
        Object yAsObject = y;
        System.out.println("2. x.equals(y)=" + x.equals(y) + " x.equals(yAsObject)=" + x.equals(yAsObject)
                + " List.of(x).contains(y)=" + List.of(x).contains(y));

        Key k = new Key(1);
        Set<Key> set3 = new HashSet<>();
        set3.add(k);
        k.id = 2;
        System.out.println("3. contains(k)=" + set3.contains(k) + " remove(k)=" + set3.remove(k)
                + " size=" + set3.size() + " iterator sees id=" + set3.iterator().next().id);

        BigDecimal a = new BigDecimal("1.0"), b = new BigDecimal("1.00");
        System.out.println("4. equals=" + a.equals(b) + " compareTo=" + a.compareTo(b)
                + " HashSet size=" + new HashSet<>(List.of(a, b)).size()
                + " TreeSet size=" + new TreeSet<>(List.of(a, b)).size());
    }
}